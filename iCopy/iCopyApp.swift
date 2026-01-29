import SwiftUI
import Cocoa

@main
struct iCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var cleanupManager = ClipboardCleanupManager.shared
    @State private var showPermissionGuide = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .sheet(isPresented: $showPermissionGuide) {
                    PermissionGuideView()
                }
                .onAppear {
                    checkPermissionsOnLaunch()
                }
        }
        .commands {
            CommandGroup(replacing: .windowSize) {} // 移除窗口大小调整相关命令
        }
        .windowStyle(.hiddenTitleBar)  // 隐藏标题栏
        .windowResizability(.contentSize) // 窗口大小由内容决定，禁止用户调整
        .defaultSize(width: 880, height: 692) // 设置默认窗口大小
    }


    // 启动时检查权限
    private func checkPermissionsOnLaunch() {
        permissionManager.checkAllPermissions()

        // 延迟显示权限引导，避免与窗口初始化冲突
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !permissionManager.hasAllRequiredPermissions() {
                showPermissionGuide = true
            }
        }
    }
}

// AppDelegate 用于控制窗口行为
class AppDelegate: NSObject, NSApplicationDelegate {
    private var configuredWindows = Set<Int>() // 记录已配置的窗口
    private let hotkeyManager = HotkeyManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置所有窗口为固定大小
        setupFixedWindows()

        // 注册全局快捷键
        setupGlobalHotkeys()

        // 监听快捷键设置变化
        setupHotkeyObservers()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupFixedWindows() {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                self.configureWindow(window)
            }
        }

        // 监听新窗口创建
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let window = notification.object as? NSWindow {
                self.configureWindow(window)
            }
        }
    }

    private func configureWindow(_ window: NSWindow) {
        let windowNumber = window.windowNumber

        // 如果窗口已经配置过，只更新大小约束，不再居中
        if configuredWindows.contains(windowNumber) {
            return
        }

        // 标记窗口已配置
        configuredWindows.insert(windowNumber)

        // 设置固定窗口大小
        let fixedSize = NSSize(width: 880, height: 692)
        window.setContentSize(fixedSize)
        window.minSize = fixedSize
        window.maxSize = fixedSize

        // 移除可调整大小的样式
        window.styleMask.remove(.resizable)

        // 禁用全屏和缩放按钮
        window.collectionBehavior = [.fullScreenNone]

        // 禁用缩放按钮
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        // 只在首次配置时居中
        window.center()
    }

    // MARK: - 设置全局快捷键
    private func setupGlobalHotkeys() {
        // 从 UserDefaults 读取快捷键配置
        let showClipboardShortcut = UserDefaults.standard.string(forKey: "showClipboardShortcut") ?? "Cmd + Shift + C"
        let showPromptShortcut = UserDefaults.standard.string(forKey: "showPromptShortcut") ?? "Cmd + Shift + T"

        // 解析并注册显示剪贴板快捷键
        if let (keyCode, modifiers) = hotkeyManager.parseShortcut(showClipboardShortcut) {
            hotkeyManager.registerHotkey(id: 1, keyCode: keyCode, modifiers: modifiers) { [weak self] in
                // 每次按快捷键时都读取最新的位置设置
                let currentPosition = UserDefaults.standard.string(forKey: "pickerPosition") ?? "bottom"
                self?.showClipboardPicker(position: currentPosition)
            }
            print("📋 已注册显示剪贴板快捷键: \(showClipboardShortcut)")
        } else {
            print("⚠️ 无法解析快捷键: \(showClipboardShortcut)")
        }

        // 解析并注册显示提示词快捷键
        if let (keyCode, modifiers) = hotkeyManager.parseShortcut(showPromptShortcut) {
            hotkeyManager.registerHotkey(id: 2, keyCode: keyCode, modifiers: modifiers) { [weak self] in
                // 每次按快捷键时都读取最新的位置设置
                let currentPosition = UserDefaults.standard.string(forKey: "pickerPosition") ?? "bottom"
                self?.showPromptPicker(position: currentPosition)
            }
            print("💬 已注册显示提示词快捷键: \(showPromptShortcut)")
        } else {
            print("⚠️ 无法解析快捷键: \(showPromptShortcut)")
        }
    }

    // MARK: - 显示剪贴板选择器
    private func showClipboardPicker(position: String) {
        DispatchQueue.main.async {
            let context = PersistenceController.shared.container.viewContext
            WindowManager.shared.showClipboardPicker(position: position, context: context)
        }
    }

    // MARK: - 显示提示词选择器
    private func showPromptPicker(position: String) {
        DispatchQueue.main.async {
            let context = PersistenceController.shared.container.viewContext
            WindowManager.shared.showPromptPicker(position: position, context: context)
        }
    }

    // MARK: - 监听快捷键设置变化
    private func setupHotkeyObservers() {
        // 监听剪贴板快捷键变化
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleHotkeySettingsChange()
        }
    }

    // MARK: - 处理快捷键设置变化
    private func handleHotkeySettingsChange() {
        // 注销所有快捷键
        hotkeyManager.unregisterAllHotkeys()

        // 重新注册快捷键
        setupGlobalHotkeys()

        print("🔄 快捷键已更新")
    }
}
