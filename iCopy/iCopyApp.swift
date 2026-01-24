import SwiftUI
import Cocoa

@main
struct iCopyApp: App {
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

// 自定义 NSWindow 的行为
class FixedSizeWindow: NSWindow {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 禁用全屏功能
        self.collectionBehavior = .fullScreenNone
        
        // 禁用窗口大小调整
        self.styleMask.remove(.resizable)
        
        // 设置固定窗口大小
        let fixedSize = NSSize(width: 2000, height: 600)
        self.setContentSize(fixedSize)
        self.minSize = fixedSize
        self.maxSize = fixedSize
        
        // 屏蔽用户调整窗口行为
        self.isMovableByWindowBackground = false // 禁止从背景拖动
        
        // 窗口居中
        self.center()
    }
}
