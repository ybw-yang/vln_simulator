#!/usr/bin/env bash
# 在 conda 环境 vln_simulator 中安装 NaVid 相关依赖，避免与 Habitat / numpy / scipy 冲突。
#
# 用法:
#   conda activate vln_simulator
#   bash scripts/install_navid_deps_vln_simulator.sh
#
# 可选环境变量:
#   INSTALL_TORCH_CONDA=1   # 用 conda 安装 pytorch+torchvision（GPU，pytorch-cuda=11.8）
#   INSTALL_TORCH_CPU=1     # 用 conda 安装 CPU 版 torch（无 NVIDIA 时）
#   SKIP_TORCH=1            # 已手动装好 torch 时跳过
#   PIP_EXTRA="..."         # 追加传给 pip 的参数

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> 当前 Python 与核心版本（安装前）"
python - <<'PY'
import sys
print("python:", sys.version)
for m in ("numpy", "scipy", "torch"):
    try:
        mod = __import__(m)
        print(m + ":", getattr(mod, "__version__", "?"))
    except Exception as e:
        print(m + ": (未安装)", e)
PY

if [[ "${CONDA_DEFAULT_ENV:-}" != "vln_simulator" ]]; then
  echo "警告: 当前 conda 环境为 '${CONDA_DEFAULT_ENV:-无}'，建议先: conda activate vln_simulator" >&2
fi

# 绝不降级 numpy / scipy（habitat-sim / 之前 scipy 与 numpy 兼容修复）
echo "==> 断言 numpy 主版本为 1.26.x（与 3rdparty/habitat-sim/requirements.txt 一致）"
python - <<'PY'
import numpy as np
v = tuple(int(x) for x in np.__version__.split(".")[:2])
if v != (1, 26):
    raise SystemExit(
        f"期望 numpy 1.26.x，当前 {np.__version__}。请勿执行 pip install numpy==1.23.5。\n"
        "请先: conda install -y -c conda-forge 'numpy=1.26.4' 'scipy>=1.11,<1.15'"
    )
print("numpy OK:", np.__version__)
PY

REQ="$ROOT/requirements_navid_compat.txt"
if [[ ! -f "$REQ" ]]; then
  echo "缺少 $REQ" >&2
  exit 1
fi

if [[ "${INSTALL_TORCH_CONDA:-0}" == "1" ]] && [[ "${SKIP_TORCH:-0}" != "1" ]]; then
  echo "==> conda 安装 PyTorch（与 numpy 1.26 同环境）"
  if [[ "${INSTALL_TORCH_CPU:-0}" == "1" ]]; then
    conda install -y -c pytorch "pytorch>=2.0.1,<2.3" "torchvision>=0.15.2,<0.18" cpuonly || exit 1
  else
    conda install -y -c pytorch -c nvidia "pytorch>=2.0.1,<2.3" "torchvision>=0.15.2,<0.18" pytorch-cuda=11.8 || {
      echo "conda 安装 GPU torch 失败；无 GPU 时可试: INSTALL_TORCH_CPU=1 INSTALL_TORCH_CONDA=1 $0" >&2
      exit 1
    }
  fi
fi

if [[ "${SKIP_TORCH:-0}" != "1" ]]; then
  echo "==> 检查 torch；若缺失则用 pip 安装 torch==2.0.1 torchvision==0.15.2（与 NaVid / timm 一致）"
  python - <<'PY' || pip install ${PIP_EXTRA:-} "torch==2.0.1" "torchvision==0.15.2"
import torch
import torchvision
assert torch.__version__.startswith("2.0."), torch.__version__
assert torchvision.__version__.startswith("0.15."), torchvision.__version__
import torchvision.ops  # noqa: F401
PY
fi

echo "==> pip 安装 NaVid 兼容清单（不触碰 numpy / opencv 固定版本）"
pip install ${PIP_EXTRA:-} -r "$REQ"

# habitat-lab 的 gym_definitions 依赖 gym.envs.registration.registry.env_specs；
# 若曾误装 gym 0.26+，会触发 AttributeError。此处强制与 Habitat 对齐。
echo "==> 固定 gym==0.22.0（habitat-lab 兼容）"
pip install ${PIP_EXTRA:-} "gym==0.22.0"

# 混装时易出现 torch / torchvision 不匹配 → operator torchvision::nms does not exist
if [[ "${SKIP_REALIGN_TORCH:-0}" != "1" ]]; then
  if ! python - <<'PY' 2>/dev/null
import torchvision.ops
PY
  then
    echo "==> torchvision 与 torch 不匹配，成对重装 torch==2.0.1 torchvision==0.15.2"
    echo "    （若你使用 conda 的 GPU 版 PyTorch，可设 SKIP_REALIGN_TORCH=1 并自行 conda 对齐版本）"
    pip install ${PIP_EXTRA:-} "torch==2.0.1" "torchvision==0.15.2" --force-reinstall
  else
    echo "==> torch/torchvision 可正常 import ops（跳过成对重装）"
  fi
fi

echo "==> 安装后版本"
python - <<'PY'
import numpy as np
import scipy
print("numpy:", np.__version__)
print("scipy:", scipy.__version__)
try:
    import torch
    print("torch:", torch.__version__, "cuda:", torch.cuda.is_available())
    import torchvision
    print("torchvision:", torchvision.__version__)
    import torchvision.ops  # noqa: F401
except Exception as e:
    print("torch/torchvision:", e)
try:
    import transformers
    print("transformers:", transformers.__version__)
except Exception as e:
    print("transformers:", e)
PY

echo "==> 完成。若 NaVid 仓库在别路径，请把代码与 model_zoo 放在 PYTHONPATH 或软链到本 workspace。"
