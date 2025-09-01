# WinClip for Mac 📋

> 🎯 **一个简洁高效的 macOS 剪贴板管理器** - 按 `Option+V` 快速呼出，单击直接粘贴

<div align="center">

![Platform](https://img.shields.io/badge/macOS-12.0+-green?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.7+-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

**🚀 开箱即用 · 无需开发者权限 · 完全开源**

</div>

## ✨ 核心特性

- **⚡ 极速响应**: 按 `Option+V` 瞬间呼出，单击直接粘贴到光标处
- **🧠 智能分类**: 自动识别文本、链接、代码、图片等不同类型
- **🔍 实时搜索**: 支持模糊搜索，快速定位历史内容
- **🎨 原生设计**: 毛玻璃效果，完美融入 macOS 系统风格
- **🔐 隐私优先**: 本地存储，自动过滤敏感内容

## 📸 界面预览

```
┌─────────────────────────────────┐
│  ClipMaster          Option+V  │
├─────────────────────────────────┤
│  🔍 搜索剪贴板历史...             │
├─────────────────────────────────┤
│  全部  📝文本  🔗链接  🖼️图片      │
├─────────────────────────────────┤
│ 📝 这是复制的文本内容...  刚刚     │
│ 🔗 https://github.com/... 5分钟前 │
│ 💻 function hello() {...  10分钟前 │
└─────────────────────────────────┘
```

## 🚀 快速开始

### 方法一：直接下载运行（推荐）

1. **下载项目**
```bash
git clone https://github.com/ConstTyrone/winclip-for-mac.git
cd winclip-for-mac
```

2. **一键构建**
```bash
# 运行构建脚本
./build_app.sh

# 或者手动构建
swift build -c release
```

3. **安装应用**
```bash
# 复制到应用程序文件夹
cp -r ClipMaster.app /Applications/

# 或运行安装脚本
./install_app.sh
```

4. **首次设置**
   - 启动应用，它会出现在菜单栏
   - 系统会提示授予"辅助功能"权限
   - 前往 `系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能`
   - 勾选 ClipMaster

### 方法二：源码编译

```bash
# 克隆项目
git clone https://github.com/ConstTyrone/winclip-for-mac.git
cd winclip-for-mac

# 构建项目
swift build -c release

# 直接运行
swift run ClipMaster
```

### 方法三：Xcode 开发

```bash
# 生成 Xcode 项目
swift package generate-xcodeproj
open ClipMaster.xcodeproj

# 在 Xcode 中构建运行
```

## 🎮 使用指南

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 呼出界面 | `Option+V` | 全局快捷键，任何地方都可用 |
| 搜索内容 | 直接输入 | 支持拼音和模糊搜索 |
| 选择项目 | `↑↓` 或 鼠标 | 上下键或鼠标选择 |
| 粘贴内容 | `单击` 或 `Enter` | 选中后自动粘贴到光标处 |
| 关闭界面 | `Esc` | 取消操作并关闭 |

## 🛠 技术信息

### 系统要求
- **操作系统**: macOS 12.0 (Monterey) 或更高版本
- **架构**: Intel x64 + Apple Silicon (M1/M2) 通用支持
- **权限**: 需要辅助功能权限（用于全局快捷键和自动粘贴）

### 技术栈
- **语言**: Swift 5.7+
- **界面**: SwiftUI + AppKit
- **存储**: 本地 JSON 文件
- **依赖**: 无外部依赖，纯原生实现

### 项目结构
```
ClipMaster/
├── Sources/ClipMaster/         # 源代码
│   ├── App/                   # 应用入口
│   ├── Models/                # 数据模型
│   ├── Services/              # 核心服务（剪贴板监控、快捷键管理）
│   ├── Views/                 # SwiftUI 界面
│   └── Utils/                 # 工具扩展
├── Resources/                 # 应用图标资源
├── Tests/                     # 单元测试
└── Package.swift             # Swift 包配置
```

## 🔧 构建脚本

项目提供了便利脚本：

- **`build_app.sh`** - 完整构建应用程序包
- **`install_app.sh`** - 自动构建并安装到应用程序文件夹
- **`quick_start.sh`** - 一键快速试用（无需安装）

## 🐛 故障排除

### 常见问题

**Q: Option+V 无响应？**
```
A: 请确保已授予辅助功能权限：
   系统偏好设置 → 安全性与隐私 → 辅助功能 → 勾选 ClipMaster
```

**Q: 无法粘贴到某些应用？**
```
A: 某些应用有安全限制，请：
   1. 确保目标输入框处于激活状态
   2. 尝试先手动点击输入框
```

**Q: 应用闪退或启动失败？**
```
A: 请检查：
   1. macOS 版本是否为 12.0+
   2. 系统偏好设置中是否已授予辅助功能权限
   3. 查看控制台应用中的错误日志
```

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建功能分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交 Pull Request

## 📄 开源协议

本项目基于 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 感谢 Apple 提供优秀的 macOS 开发平台
- 感谢开源社区的贡献和支持
- 感谢所有测试用户的反馈建议

---

<div align="center">

**如果这个项目对您有帮助，请给我们一个 ⭐ Star！**

Made with ❤️ for macOS users

</div>