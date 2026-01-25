import SwiftUI
import Cocoa

@main
struct iCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var permissionManager = PermissionManager.shared
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
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置所有窗口为固定大小
        setupFixedWindows()
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

        // 窗口居中
        window.center()
    }
}
