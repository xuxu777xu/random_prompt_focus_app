# 专注计时应用 (Focus Timer App)

一个基于 Flutter Desktop 的原生GUI桌面专注计时应用，实现番茄工作法的专注管理系统。

![Flutter](https://img.shields.io/badge/Flutter-3.32.5-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📖 项目简介

专注计时应用是一个现代化的桌面专注管理工具，采用科学的番茄工作法（90分钟专注 + 20分钟休息），结合智能注意力监测系统，帮助用户提高工作效率和专注力。

### 🎯 核心特性

- **🍅 番茄工作法**：90分钟专注时间 + 20分钟休息时间的科学配比
- **🧠 智能注意力监测**：基于指数分布算法的随机提示系统
- **📊 数据可视化**：丰富的统计图表和趋势分析
- **🎨 现代化界面**：Material Design 3 设计语言
- **💾 数据持久化**：本地 SQLite 数据库存储
- **🔧 个性化设置**：可自定义时长、主题、音效等
- **🎵 音频反馈**：多种内置提示音效

## 🚀 功能特色

### 计时器功能
- ⏱️ **动态圆环计时器**：美观的进度显示和平滑动画
- ▶️ **完整控制**：开始、暂停、继续、停止、重置、跳过
- 🔄 **自动切换**：专注和休息阶段的智能切换
- 📱 **状态显示**：实时显示当前状态和剩余时间

### 注意力监测
- 🎯 **随机提示**：基于指数分布的科学提示算法
- 💭 **走神统计**：记录和分析注意力分散情况
- ⏰ **可配置频率**：自定义提示频率和超时时间
- 🎭 **美观界面**：半透明浮层提示对话框

### 数据统计
- 📈 **多维度统计**：专注时长、完成会话、走神次数等
- 📊 **可视化图表**：柱状图、饼图、趋势线图
- 📅 **时间范围**：今日、本周、本月、自定义范围
- 🏆 **效率分析**：专注效率和时间分布分析

### 个性化设置
- ⏲️ **时长调节**：专注时长（15-180分钟）、休息时长（5-60分钟）
- 🌓 **主题切换**：浅色、深色、跟随系统
- 🔊 **音频设置**：多种内置音效、音量调节
- 🔧 **行为配置**：自动启动、注意力监测等

## 🛠️ 技术架构

### 核心技术栈
- **框架**: Flutter Desktop (原生GUI)
- **语言**: Dart
- **状态管理**: Provider
- **本地存储**: sqflite (SQLite)
- **图表库**: fl_chart
- **音频播放**: audioplayers

### 项目结构
```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
│   ├── session.dart       # 会话模型
│   ├── settings.dart      # 设置模型
│   └── statistics.dart    # 统计模型
├── providers/             # 状态管理
│   ├── timer_provider.dart    # 计时器状态
│   ├── settings_provider.dart # 设置状态
│   └── data_provider.dart     # 数据状态
├── screens/               # 页面
│   ├── main_screen.dart       # 主屏幕
│   ├── timer_screen.dart      # 计时器屏幕
│   ├── statistics_screen.dart # 统计屏幕
│   └── settings_screen.dart   # 设置屏幕
├── widgets/               # 自定义组件
│   ├── circular_timer.dart    # 圆环计时器
│   ├── prompt_overlay.dart    # 提示浮层
│   └── statistics_charts.dart # 统计图表
├── services/              # 业务服务
│   ├── database_service.dart  # 数据库服务
│   ├── audio_service.dart     # 音频服务
│   ├── system_tray_service.dart # 系统托盘服务
│   └── window_service.dart    # 窗口服务
└── utils/                 # 工具函数
```

## 📋 系统要求

- **操作系统**: Windows 10 或更高版本
- **Flutter**: 3.32.5 或更高版本
- **Dart**: 3.5.0 或更高版本
- **Visual Studio**: 2022 (包含 C++ 工具)

## 🚀 快速开始

### 1. 环境准备

确保已安装 Flutter 开发环境：

```bash
# 检查 Flutter 环境
flutter doctor

# 确保 Windows 开发环境正常
flutter doctor -v
```

### 2. 克隆项目

```bash
git clone <repository-url>
cd focus_timer_app
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 运行应用

```bash
# 运行在 Windows 桌面
flutter run -d windows

# 或者构建发布版本
flutter build windows
```

## 📱 使用指南

### 基本使用流程

1. **启动应用**：双击运行应用程序
2. **开始专注**：点击"开始"按钮开始专注会话
3. **注意力检查**：在专注过程中会随机弹出注意力检查提示
4. **查看统计**：在统计页面查看专注数据和趋势
5. **个性化设置**：在设置页面调整时长、主题等配置

### 高级功能

- **自定义时长**：在设置中调整专注和休息时间
- **主题切换**：支持浅色、深色和跟随系统主题
- **数据分析**：查看详细的专注统计和趋势图表
- **音效设置**：选择喜欢的提示音效和音量

## 🔧 开发指南

### 开发环境设置

1. 安装 Flutter SDK
2. 配置 Windows 开发环境
3. 安装 Visual Studio 2022
4. 克隆项目并安装依赖

### 代码规范

- 使用 Dart 官方代码风格
- 遵循 Flutter 最佳实践
- 保持代码注释的完整性
- 使用 Provider 进行状态管理

### 构建和部署

```bash
# 开发模式运行
flutter run -d windows

# 构建发布版本
flutter build windows --release

# 生成安装包（需要额外工具）
# 可以使用 MSIX 或 Inno Setup 等工具
```

## 🐛 已知问题

1. **音频文件缺失**：首次运行时可能缺少音频文件，会使用系统默认音效
2. **系统托盘**：系统托盘功能正在开发中
3. **自启动功能**：开机自启动功能待完善

## 🔮 未来计划

- [ ] 完善系统托盘功能
- [ ] 添加开机自启动
- [ ] 实现数据导出功能
- [ ] 添加更多统计维度
- [ ] 支持自定义音频文件
- [ ] 实现云同步功能
- [ ] 添加多语言支持

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件
- 项目讨论区

---

**专注计时应用** - 让专注成为习惯，让效率成为常态！ 🚀
