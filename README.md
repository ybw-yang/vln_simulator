# README.md

![](./documents/images/image.png)
## 一. 项目作用
用于作为一个简单的室内环境的仿真器平台
- 加载环境
  - 加载指定的几个数据集的某几个室内环境
  - [MANUAL CONTROL] 加载室内环境带有可能随机出生的物体
- ROS2消息发送/接收/录制ROS bag:
  - 消息发送:
    - 机器人位姿
    - 机器人传感器这一帧的RGBD信息（正中相机 + 可选左右目 RGB）
    - 机器人传感器这一帧的深度信息
    - [TODO] 机器人传感器这一帧的语义分割的ground_truth信息
  - [TODO]生成文件，但是没有以ROS消息的形式发送出来
    - 所有类别物体的检测框(class_bbox.json)
    - 所有类别物体的数量(class_num.json)
  - 消息接收:
    - 接收ROS2的轨迹指令，视角按照轨迹进行移动
    - 接收ROS2的odom指令，直接控制机器人在habitat-sim环境中的位置
  - 录制ROS bag
    - 录制对应的ROS2 bag用于建图等方面的测试

---



## 二. 环境安装

> 此设置已在 **Ubuntu 22.04** 和 **Python 3.10** 上通过测试。

#### 2.1 克隆带有子模块的仓库

```bash

# 强烈建议将项目放置在Documents路径下
cd ~/Documents
git clone --recurse-submodules git@github.com:Tipriest/vln_simulator.git
cd vln_simulator

# 如果上面的git clone的部分因为网络问题导致没有clone完全的话
# 可以运行下面的指令对上面的包进行补充

git submodule update --init --recursive
```

#### 2.2 创建 Conda 环境

```bash
conda env create -f environment.yml
conda activate vln_simulator
```

#### 2.3（可选）在同一环境中安装 NaVid / Uni-NaVid 依赖

NaVid 官方 `requirements.txt` 固定 `numpy==1.23.5`，与本子模块 **habitat-sim** 要求的 **`numpy==1.26.4`** 冲突。请在 **不要降级 numpy** 的前提下，使用仓库内的兼容清单安装其余库：

```bash
conda activate vln_simulator
# 建议先用 conda 安装 PyTorch（与 numpy 1.26 同环境，二选一）：
# GPU: INSTALL_TORCH_CONDA=1 bash scripts/install_navid_deps_vln_simulator.sh
# CPU: INSTALL_TORCH_CONDA=1 INSTALL_TORCH_CPU=1 bash scripts/install_navid_deps_vln_simulator.sh
# 若 torch 已装好：SKIP_TORCH=1 bash scripts/install_navid_deps_vln_simulator.sh
bash scripts/install_navid_deps_vln_simulator.sh
```

#### 3. 编译并安装 Habitat Sim & Lab

> 此步骤需要一些时间，因为它会从源码编译 Habitat-Sim。
> Habitat 无法通过 conda 在 Python 3.10 中直接安装，因此必须手动编译。

```bash
bash scripts/install_habitat.sh
# 这里编译的时候有可能会出现一个什么包装不了的问题，需要删掉3rdparty路径下的habitat-sim文件夹重新运行下面的命令:
git submodule update --init --recursive

```

> 在编译 habitat-sim 过程中，如果遇到 OpenGL 错误（如 `Could NOT find OpenGL`）或编译 `zlib_external` 时出错，请安装以下依赖库：
```bash
 sudo apt install libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev zlib1g-dev
 sudo apt-get install -y ros-humble-rmw-cyclonedds-cpp
```

## 三. 数据集设置

在运行工具之前，请按照 [数据集设置指南](documents/dataset/dataset_netdisk.md) 准备所需的数据集。

## 四. 运行采集器

从根目录运行主仿真程序：

```bash
python -m habitat_data_collector.main
```

默认情况下，它使用位于 `config/habitat_data_collector.yaml` 的配置文件。有关配置详情，请参阅 [配置参考](documents/config_reference/config_reference.md)。

与 Gazebo 等仿真联调时，建议统一开启仿真时钟：

```bash
python -m habitat_data_collector.main
# 或命令行覆盖（Hydra 语法用 =，不是 ROS 的 :=）：
python -m habitat_data_collector.main use_sim_time=true
python -m habitat_data_collector.main use_sim_time=false
# 或在 habitat_data_collector.yaml 中设置 use_sim_time: true
```

`use_sim_time: true` 且 **`publish_sim_clock: false`（默认）** 时，图像 stamp 与 **Gazebo 的 `/clock`** 一致；请确保 Gazebo 以 `use_sim_time` 启动。仅无 Gazebo 单机调试时设 `publish_sim_clock: true`。



## 五. 用户指南

1. **仿真器成功启动后，请参阅 [使用指南](documents/usage/usage_zh.md) 了解如何**：

- 移动相机并探索场景
- 添加、放置、抓取和删除物体
- 开始和停止录制（原始数据 + ROS2 bag）
- 保存并重新加载场景配置

该指南包含视觉预览和终端输出示例，以便更好地理解。

2. [与vln_gazebo_simulator的坐标转换问题说明](./documents/坐标转换.md)




## 🔗 引用
如果您觉得我们的工作有帮助，请考虑给这个仓库点个星 🌟 并引用：
```
@article{jiang2025dualmap,
  title={DualMap: Online Open-Vocabulary Semantic Mapping for Natural Language Navigation in Dynamic Changing Scenes},
  author={Jiang, Jiajun and Zhu, Yiming and Wu, Zirui and Song, Jie},
  journal={arXiv preprint arXiv:2506.01950},
  year={2025}
}
```

## 🙏 致谢
本项目建立在以下杰出工作的基础之上：
- Habitat-Sim
- Habitat-Lab
感谢这些项目的作者和贡献者将其开源并积极维护。

本项目还受到 VLMaps 数据采集流程的启发，我们感谢 HOVSG 和 VLMaps 的作者所做的贡献。

特别感谢 @TOM-Huang 和 @aclegg3 在开发过程中提供的宝贵建议和支持。

