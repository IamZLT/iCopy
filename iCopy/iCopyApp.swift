import SwiftUI
import Cocoa

@main
struct iCopyApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(replacing: .windowSize) {} // 移除窗口大小调整相关命令
        }
        .windowStyle(.hiddenTitleBar)  // 隐藏标题栏
    }
    
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("需要辅助功能权限")
            DispatchQueue.main.async {
                self.showAlertForAccessibilityPermission()
            }
        }
    }
    
    private func showAlertForAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "权限警告"
        alert.informativeText = "应用程序需要辅助功能权限才能正常工作。请在系统偏好设置中启用此权限。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
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
