# iCopy - 智能剪贴板与提示词管理工具

[![macOS](https://img.shields.io/badge/macOS-11.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📖 项目简介

iCopy 是一个功能强大的 macOS 应用，集成了**剪贴板历史管理**和 **AI 提示词管理**功能，帮助您更高效地使用大语言模型和管理日常复制内容。

### 核心功能

#### 📋 剪贴板管理
- 自动记录所有复制内容的历史
- 支持文本、图片、文件、文件夹等多种类型
- 快捷键快速调出历史记录选择器
- 智能搜索和过滤功能
- 可配置最大历史记录数量和自动清理间隔

#### 💬 提示词管理（新功能）
- 分类管理提示词（编程、写作、翻译、分析等）
- 收藏常用提示词，快速访问
- 标签系统，灵活组织提示词
- 一键复制提示词到剪贴板
- 全文搜索，快速定位所需提示词
- 全局快捷键快速调出提示词选择器

## 🚀 快速开始

### 系统要求
- macOS 11.0 或更高版本
- Xcode 13.0 或更高版本（开发）

### 安装步骤

1. 克隆项目到本地
```bash
git clone https://github.com/yourusername/iCopy.git
cd iCopy
```

2. 使用 Xcode 打开项目
```bash
open iCopy.xcodeproj
```

3. 编译并运行
- 选择目标设备（Mac）
- 点击运行按钮或按 `Cmd + R`

### 首次使用配置

1. **授予权限**：首次启动时需要授予以下权限
   - **辅助功能权限**（必需）
     - 用途：监听全局快捷键和键盘事件
     - 设置路径：系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能

   - **完全磁盘访问权限**（必需）
     - 用途：访问剪贴板历史和文件操作
     - 设置路径：系统偏好设置 → 安全性与隐私 → 隐私 → 完全磁盘访问

   应用会在首次启动时自动显示权限引导界面，帮助您完成权限配置。

2. **配置快捷键**：在"通用设置"中自定义快捷键
   - 打开应用：`Cmd + Shift + O`（默认）
   - 显示剪贴板：`Cmd + Shift + C`（默认）
   - 显示提示词：`Cmd + Shift + T`（默认）

3. **添加提示词**：进入"提示词管理"，创建您的第一个提示词

## 📚 使用指南

### 剪贴板管理
1. 应用会自动记录您复制的所有内容
2. 按 `Cmd + Shift + C` 调出剪贴板历史选择器
3. 使用搜索框快速查找历史内容
4. 点击任意项目即可复制到剪贴板

### 提示词管理
1. 在侧边栏点击"提示词管理"进入管理界面
2. 点击"添加提示词"按钮创建新提示词
3. 填写标题、选择分类、输入内容
4. 可选：添加标签、设置为收藏
5. 按 `Cmd + Shift + T` 快速调出提示词选择器
6. 点击提示词卡片即可复制到剪贴板

## 🏗️ 项目架构

### 技术栈
- **语言**：Swift 5.5+
- **框架**：SwiftUI, AppKit
- **数据持久化**：Core Data
- **系统集成**：NSPasteboard, Accessibility APIs

### 核心模块

项目采用模块化架构，按功能划分目录：

```
iCopy/
├── iCopyApp.swift              # 应用入口
├── ContentView.swift            # 主界面导航
│
├── Models/                     # 数据模型层
│   ├── ClipboardHistory.xcdatamodeld/  # Core Data 模型
│   ├── ClipboardType.swift     # 剪贴板类型枚举
│   └── PersistenceController.swift     # 数据持久化控制器
│
├── Features/                   # 功能模块
│   ├── Clipboard/              # 剪贴板功能
│   │   ├── HistoryClipboardView.swift
│   │   ├── ClipboardPickerView.swift
│   │   └── ClipboardPickerCardView.swift
│   ├── Prompt/                 # 提示词功能
│   │   ├── PromptManagementView.swift
│   │   ├── PromptEditorView.swift
│   │   ├── PromptCardView.swift
│   │   ├── PromptPickerView.swift
│   │   └── PromptPickerCardView.swift
│   └── Settings/               # 设置功能
│       └── SettingsView.swift
│
├── Utils/                      # 工具类
│   ├── DiskPermissionManager.swift
│   ├── CustomContainerView.swift
│   ├── KeyEventHandlerView.swift
│   └── NoFocusRingView.swift
│
└── Components/                 # 通用组件（预留）
```

详细架构说明请查看 [ARCHITECTURE.md](ARCHITECTURE.md)

### 数据模型
- **ClipboardItem**：剪贴板历史项
  - content: 内容
  - contentType: 类型（TEXT/IMAGE/FILE/FOLDER）
  - timestamp: 时间戳
  - title: 标题
  - filePath: 文件路径

- **PromptItem**：提示词项
  - id: 唯一标识
  - title: 标题
  - content: 内容
  - category: 分类
  - tags: 标签
  - isFavorite: 是否收藏
  - createdAt: 创建时间
  - updatedAt: 更新时间

## 📝 开发进度

### v2.0.0 (2026-01-25) - 重大更新
- ✅ 添加提示词管理功能
- ✅ 重构 Core Data 模型
- ✅ 创建提示词管理界面
- ✅ 创建提示词选择器弹窗
- ✅ 创建剪贴板选择器弹窗
- ✅ 更新设置界面，支持新快捷键配置
- ✅ 完善项目文档

### v1.0.0 (2023-10-15) - 初始版本
- ✅ 基础剪贴板历史管理
- ✅ 快捷键设置
- ✅ 自动清理功能

## 🤝 贡献指南

欢迎任何形式的贡献！请遵循以下步骤：

1. Fork 本项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 📧 联系方式

如有问题或建议，请提交 Issue 或 Pull Request。

---

**Made with ❤️ for macOS users**
