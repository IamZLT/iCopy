# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-25

### Added
- **提示词管理功能**：全新的 AI 提示词管理系统
  - 支持创建、编辑、删除提示词
  - 分类管理（编程、写作、翻译、分析、其他）
  - 收藏功能，快速访问常用提示词
  - 标签系统，灵活组织提示词
  - 全文搜索功能
  - 一键复制提示词到剪贴板

- **提示词选择器**：快速调出提示词的弹窗界面
  - 支持搜索和分类筛选
  - 悬停高亮效果
  - 快捷键支持 (Cmd + Shift + T)

- **剪贴板选择器**：优化的剪贴板历史选择界面
  - 快速搜索功能
  - 类型图标和颜色区分
  - 快捷键支持 (Cmd + Shift + C)

- **新增快捷键配置**
  - 显示剪贴板选择器快捷键
  - 显示提示词选择器快捷键

### Changed
- 重构 Core Data 模型，添加 PromptItem 实体
- 更新主界面导航，添加"提示词管理"入口
- 优化设置界面布局，支持更多快捷键配置
- 完善项目文档和架构说明

### Technical
- 新增文件：
  - `PromptManagementView.swift` - 提示词管理主界面
  - `PromptEditorView.swift` - 提示词编辑器
  - `PromptPickerView.swift` - 提示词选择器
  - `PromptCardView.swift` - 提示词卡片组件
  - `PromptPickerCardView.swift` - 提示词选择卡片组件
  - `ClipboardPickerView.swift` - 剪贴板选择器
  - `ClipboardPickerCardView.swift` - 剪贴板选择卡片组件

## [1.0.0] - 2023-10-15

### Added
- 剪贴板历史管理功能
  - 自动记录复制内容
  - 支持文本、图片、文件、文件夹等多种类型
  - 轮播式历史展示界面
  - 键盘和手势导航支持

- 快捷键设置
  - 打开应用快捷键配置
  - 快速粘贴快捷键配置
  - 实时键盘事件捕获

- 剪贴板历史管理
  - 可配置最大历史记录数量
  - 自动清理间隔设置（0-30天）

- Core Data 数据持久化
  - ClipboardItem 实体
  - 自动迁移支持
  - 错误恢复机制

### Technical
- 基于 SwiftUI 构建的现代化 macOS 应用
- 使用 Core Data 进行数据持久化
- 集成 NSPasteboard 进行剪贴板监控
- 使用 Accessibility APIs 实现全局快捷键

---

## 版本说明

### 版本号规则
- **主版本号**：重大功能更新或架构变更
- **次版本号**：新功能添加
- **修订号**：Bug 修复和小改进

### 发布周期
- 主版本：根据功能规划发布
- 次版本：每月或根据功能完成度发布
- 修订版：根据 Bug 修复需求发布
