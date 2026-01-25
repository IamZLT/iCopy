import SwiftUI
import AppKit

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
        window.styleMask = [.titled, .closable, .miniaturizable]
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
}
