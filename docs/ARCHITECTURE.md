# iCopy 架构设计文档

## 📐 项目结构

本项目采用模块化的文件组织结构，按功能模块划分目录，便于维护和扩展。

```
iCopy/
├── iCopy/                          # 主应用目录
│   ├── iCopyApp.swift              # 应用入口
│   ├── ContentView.swift           # 主界面导航
│   ├── Info.plist                  # 应用配置
│   ├── iCopy.entitlements          # 权限配置
│   │
│   ├── Models/                     # 数据模型层
│   │   ├── ClipboardHistory.xcdatamodeld/  # Core Data 模型
│   │   ├── ClipboardType.swift     # 剪贴板类型枚举
│   │   └── PersistenceController.swift     # 数据持久化控制器
│   │
│   ├── Features/                   # 功能模块
│   │   ├── Clipboard/              # 剪贴板功能模块
│   │   │   ├── HistoryClipboardView.swift      # 历史记录主视图
│   │   │   ├── ClipboardPickerView.swift       # 选择器弹窗
│   │   │   └── ClipboardPickerCardView.swift   # 选择器卡片组件
│   │   │
│   │   ├── Prompt/                 # 提示词功能模块
│   │   │   ├── PromptManagementView.swift      # 管理主视图
│   │   │   ├── PromptEditorView.swift          # 编辑器视图
│   │   │   ├── PromptCardView.swift            # 卡片组件
│   │   │   ├── PromptPickerView.swift          # 选择器弹窗
│   │   │   └── PromptPickerCardView.swift      # 选择器卡片组件
│   │   │
│   │   └── Settings/               # 设置功能模块
│   │       └── SettingsView.swift  # 设置界面
│   │
│   ├── Utils/                      # 工具类
│   │   ├── ClipboardCleanupManager.swift   # 剪贴板自动清理管理
│   │   ├── QuickLookManager.swift          # Quick Look 预览管理
│   │   ├── WindowManager.swift             # 窗口管理
│   │   ├── HotkeyManager.swift             # 全局快捷键管理
│   │   ├── PermissionManager.swift         # 权限管理
│   │   ├── KeyEventHandlerView.swift       # 键盘事件处理
│   │   └── NoFocusRingView.swift           # 无焦点环视图
│   │
│   ├── Components/                 # 通用组件（预留）
│   │
│   └── Assets.xcassets/            # 资源文件
│
├── iCopyTests/                     # 单元测试
├── iCopyUITests/                   # UI 测试
├── README.md                       # 项目说明
├── CHANGELOG.md                    # 版本变更日志
└── ARCHITECTURE.md                 # 架构设计文档（本文件）
```

## 🏗️ 架构设计原则

### 1. 模块化设计
- **按功能划分**：每个功能模块独立在 `Features/` 目录下
- **职责单一**：每个模块只负责自己的业务逻辑
- **低耦合**：模块间通过数据模型和协议通信

### 2. 分层架构
```
┌─────────────────────────────────────┐
│         Presentation Layer          │  视图层（SwiftUI Views）
│   (Features/Clipboard, Prompt...)   │
├─────────────────────────────────────┤
│         Business Logic Layer        │  业务逻辑层
│      (ViewModels, Services)         │
├─────────────────────────────────────┤
│          Data Layer                 │  数据层
│   (Models, PersistenceController)   │
├─────────────────────────────────────┤
│         Utility Layer               │  工具层
│    (Utils, Components)              │
└─────────────────────────────────────┘
```

### 3. 代码组织规范
- **命名规范**：使用清晰的命名，见名知意
- **文件职责**：一个文件只包含一个主要的 View 或 Model
- **代码复用**：通用组件放在 `Components/` 目录
- **工具函数**：辅助功能放在 `Utils/` 目录

## 📦 模块详解

### Models 层
**职责**：数据模型定义和数据持久化管理

- `ClipboardHistory.xcdatamodeld`：Core Data 数据模型
  - `ClipboardItem`：剪贴板历史项实体
  - `PromptItem`：提示词实体

- `PersistenceController.swift`：Core Data 管理器
  - 单例模式
  - 自动迁移支持
  - 错误恢复机制

- `ClipboardType.swift`：剪贴板类型枚举
  - TEXT, IMAGE, FILE, FOLDER, MEDIA, OTHER

### Features 层

#### Clipboard 模块
**职责**：剪贴板历史管理功能

- `HistoryClipboardView.swift`：历史记录主视图
  - 轮播式展示
  - 键盘和手势导航
  - 实时监控剪贴板

- `ClipboardPickerView.swift`：快速选择器弹窗
  - 搜索功能
  - 类型筛选
  - 快捷键调出

- `ClipboardPickerCardView.swift`：选择器卡片组件
  - 类型图标展示
  - 悬停效果
  - 时间格式化

#### Prompt 模块
**职责**：AI 提示词管理功能

- `PromptManagementView.swift`：管理主视图
  - 列表展示
  - 搜索和分类筛选
  - 添加/编辑/删除操作

- `PromptEditorView.swift`：编辑器视图
  - 创建/编辑提示词
  - 分类选择
  - 标签管理
  - 收藏功能

- `PromptCardView.swift`：卡片组件
  - 详细信息展示
  - 一键复制
  - 操作按钮（编辑/删除）

- `PromptPickerView.swift`：快速选择器弹窗
  - 搜索和分类筛选
  - 快捷键调出
  - 点击选择并复制

- `PromptPickerCardView.swift`：选择器卡片组件
  - 简洁展示
  - 悬停效果
  - 分类颜色标识

#### Settings 模块
**职责**：应用设置和配置

- `SettingsView.swift`：设置界面
  - 快捷键配置
  - 历史记录管理设置
  - 自动清理配置

### Utils 层
**职责**：通用工具类和辅助功能

- `ClipboardCleanupManager.swift`：剪贴板自动清理管理
  - 单例模式，全局管理清理任务
  - 定时检查和执行清理（每小时）
  - 计算和更新下次清理倒计时
  - 使用 CoreData 批量删除优化性能

- `QuickLookManager.swift`：Quick Look 预览管理
  - 管理 macOS 原生预览窗口
  - 支持多种文件类型预览

- `WindowManager.swift`：窗口管理
  - 管理弹窗的显示和隐藏
  - 控制窗口位置和层级

- `HotkeyManager.swift`：全局快捷键管理
  - 注册和监听全局快捷键
  - 快捷键解析和验证

- `PermissionManager.swift`：权限管理
  - 检查辅助功能权限
  - 检查通知权限

- `KeyEventHandlerView.swift`：键盘事件处理
- `NoFocusRingView.swift`：无焦点环视图

### Components 层
**职责**：可复用的通用组件（预留扩展）

目前为空，未来可添加：
- 通用按钮组件
- 通用输入框组件
- 通用弹窗组件
- 等等...

## 🔄 数据流

### 剪贴板数据流
```
NSPasteboard → HistoryClipboardView → Core Data → ClipboardItem
                                                         ↓
                                              ClipboardPickerView
                                                         ↓
                                          ClipboardCleanupManager
                                          (定时清理过期数据)
```

### 自动清理数据流
```
App启动 → ClipboardCleanupManager初始化
              ↓
         定时器启动（每小时检查）
              ↓
    检查autoCleanInterval设置
              ↓
    计算下次清理时间 → 更新倒计时显示
              ↓
    到达清理时间 → 批量删除过期ClipboardItem
              ↓
         保存清理时间 → 重新计算下次清理
```

### 提示词数据流
```
User Input → PromptEditorView → Core Data → PromptItem
                                                  ↓
                                       PromptManagementView
                                                  ↓
                                        PromptPickerView
```

## 🚀 扩展指南

### 添加新功能模块

1. 在 `Features/` 下创建新的功能文件夹
2. 按照现有模块的结构组织文件
3. 如需数据持久化，在 Core Data 模型中添加实体
4. 在 `ContentView.swift` 中添加导航入口

### 添加通用组件

1. 在 `Components/` 目录下创建组件文件
2. 确保组件具有良好的复用性
3. 提供清晰的接口和文档注释

### 添加工具类

1. 在 `Utils/` 目录下创建工具类文件
2. 使用静态方法或单例模式
3. 确保功能独立，无副作用

## 📋 最佳实践

### 代码规范
- 使用 SwiftUI 的声明式语法
- 遵循 Swift 命名规范
- 添加必要的注释和文档
- 保持函数简洁，单一职责

### 性能优化
- 使用 `@FetchRequest` 进行数据查询
- 合理使用 `LazyVStack` 和 `LazyHStack`
- 避免在主线程进行耗时操作
- 使用 `@State` 和 `@Binding` 管理状态

### 测试建议
- 为核心业务逻辑编写单元测试
- 为关键用户流程编写 UI 测试
- 测试文件放在对应的测试目录

---

**文档版本**: v2.1.0
**最后更新**: 2026-01-29
