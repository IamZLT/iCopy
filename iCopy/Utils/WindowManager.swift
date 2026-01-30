import SwiftUI
import AppKit
import CoreData

// MARK: - 自定义面板类，支持无边框面板接收键盘事件
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

class WindowManager {
    static let shared = WindowManager()

    private var windows: [String: NSWindow] = [:]

    func showWindow<Content: View>(
        id: String,
        title: String,
        size: NSSize,
        content: Content
    ) {
        // 如果窗口已存在，直接显示
        if let existingWindow = windows[id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // 创建新窗口
        let hostingController = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hostingController)

        window.title = title
        window.setContentSize(size)
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 保存窗口引用
        windows[id] = window

        // 监听窗口关闭事件
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.windows.removeValue(forKey: id)
        }
    }

    func closeWindow(id: String) {
        windows[id]?.close()
        windows.removeValue(forKey: id)
    }

    // MARK: - 显示提示词选择器
    func showPromptPicker(position: String, context: NSManagedObjectContext) {
        let windowId = "promptPicker"

        // 关闭剪贴板选择器（互斥）
        closeWindow(id: "clipboardPicker")

        // 如果窗口已存在，先关闭
        closeWindow(id: windowId)

        // 创建提示词选择器视图
        let pickerView = PromptPickerView(
            isPresented: .constant(true),
            onSelect: { prompt in
                // 复制提示词内容到剪贴板
                self.copyPromptToClipboard(prompt)
                self.closeWindow(id: windowId)
            }
        )
        .environment(\.managedObjectContext, context)

        // 创建窗口
        let hostingController = NSHostingController(rootView: pickerView)
        let window = createPickerWindow(hostingController: hostingController, position: position)

        // 保存窗口引用
        windows[windowId] = window

        // 监听窗口失去焦点事件，但排除 QuickLook 窗口
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            // 延迟检查，确保新的 key window 已经设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 如果新的 key window 是 QuickLook 窗口，不关闭面板
                if let newKeyWindow = NSApp.keyWindow,
                   newKeyWindow.className.contains("QLPreviewPanel") {
                    return
                }
                // 否则关闭面板
                self?.closeWindow(id: windowId)
            }
        }

        // 显示窗口并确保获得焦点
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 在显示后再次设置位置，确保位置正确
        DispatchQueue.main.async {
            self.repositionWindow(window, position: position)
        }

        // 确保窗口成为主窗口并接收键盘事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeKey()
        }
    }

    // MARK: - 显示剪贴板选择器
    func showClipboardPicker(position: String, context: NSManagedObjectContext) {
        let windowId = "clipboardPicker"

        // 关闭提示词选择器（互斥）
        closeWindow(id: "promptPicker")

        // 如果窗口已存在，先关闭
        closeWindow(id: windowId)

        // 创建剪贴板选择器视图
        let pickerView = ClipboardPickerView(
            isPresented: .constant(true),
            onSelect: { item in
                // 复制到剪贴板
                self.copyItemToClipboard(item)
                self.closeWindow(id: windowId)
            }
        )
        .environment(\.managedObjectContext, context)

        // 创建窗口
        let hostingController = NSHostingController(rootView: pickerView)
        let window = createPickerWindow(hostingController: hostingController, position: position)

        // 保存窗口引用
        windows[windowId] = window

        // 监听窗口失去焦点事件，但排除 QuickLook 窗口
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            // 延迟检查，确保新的 key window 已经设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 如果新的 key window 是 QuickLook 窗口，不关闭面板
                if let newKeyWindow = NSApp.keyWindow,
                   newKeyWindow.className.contains("QLPreviewPanel") {
                    return
                }
                // 否则关闭面板
                self?.closeWindow(id: windowId)
            }
        }

        // 显示窗口并确保获得焦点
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 在显示后再次设置位置，确保位置正确
        DispatchQueue.main.async {
            self.repositionWindow(window, position: position)
        }

        // 确保窗口成为主窗口并接收键盘事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeKey()
        }
    }

    // MARK: - 创建选择器窗口
    private func createPickerWindow(hostingController: NSHostingController<some View>, position: String) -> NSWindow {
        // 创建面板
        let panel = KeyablePanel(contentViewController: hostingController)

        // 设置面板样式
        panel.styleMask = [.borderless, .fullSizeContentView]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.acceptsMouseMovedEvents = true

        // 关键设置：点击外部区域自动关闭
        panel.hidesOnDeactivate = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false

        // 设置窗口位置和大小
        guard let screen = NSScreen.main else { return panel }
        let screenFrame = screen.visibleFrame

        let windowFrame: NSRect

        switch position {
        case "top":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.maxY - 400,
                width: screenFrame.width,
                height: 400
            )
        case "bottom":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: 400
            )
        case "left":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: 300,
                height: screenFrame.height
            )
        case "right":
            windowFrame = NSRect(
                x: screenFrame.maxX - 300,
                y: screenFrame.minY,
                width: 300,
                height: screenFrame.height
            )
        default: // bottom
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: 400
            )
        }

        panel.setFrame(windowFrame, display: false)

        return panel
    }

    // MARK: - 重新定位窗口
    private func repositionWindow(_ window: NSWindow, position: String) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        let windowFrame: NSRect

        switch position {
        case "top":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.maxY - 400,
                width: screenFrame.width,
                height: 400
            )
        case "bottom":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: 400
            )
        case "left":
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: 300,
                height: screenFrame.height
            )
        case "right":
            windowFrame = NSRect(
                x: screenFrame.maxX - 300,
                y: screenFrame.minY,
                width: 300,
                height: screenFrame.height
            )
        default: // bottom
            windowFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: 400
            )
        }

        window.setFrame(windowFrame, display: true, animate: false)
    }

    // MARK: - 复制到剪贴板
    private func copyItemToClipboard(_ item: ClipboardItem) {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch type {
        case .text:
            pasteboard.setString(item.content ?? "", forType: .string)
        case .image, .file, .media, .folder:
            if let path = item.content {
                let url = URL(fileURLWithPath: path)
                pasteboard.writeObjects([url as NSPasteboardWriting])
            }
        case .other:
            break
        }
    }

    // MARK: - 复制提示词到剪贴板
    private func copyPromptToClipboard(_ prompt: PromptItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt.content ?? "", forType: .string)
    }
}
