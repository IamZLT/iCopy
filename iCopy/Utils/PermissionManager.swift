import Foundation
import AppKit
import Cocoa

/// 权限类型枚举
enum PermissionType: String, CaseIterable {
    case accessibility = "辅助功能"

    var description: String {
        switch self {
        case .accessibility:
            return "用于监听全局快捷键和剪贴板变化"
        }
    }

    var icon: String {
        switch self {
        case .accessibility:
            return "hand.raised.fill"
        }
    }
}

/// 权限状态
enum PermissionStatus {
    case granted      // 已授权
    case denied       // 已拒绝
    case notDetermined // 未确定
}

/// 统一的权限管理器
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var accessibilityStatus: PermissionStatus = .notDetermined

    private init() {
        checkAllPermissions()
    }

    /// 检查所有权限状态
    func checkAllPermissions() {
        accessibilityStatus = checkAccessibilityPermission()
    }

    /// 检查是否所有必需权限都已授予
    func hasAllRequiredPermissions() -> Bool {
        return accessibilityStatus == .granted
    }

    // MARK: - 辅助功能权限

    /// 检查辅助功能权限
    private func checkAccessibilityPermission() -> PermissionStatus {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled ? .granted : .denied
    }

    /// 请求辅助功能权限
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)

        // 延迟检查权限状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAllPermissions()
        }
    }

    /// 打开辅助功能设置
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - 通用方法

    /// 打开指定权限的系统设置
    func openSettings(for type: PermissionType) {
        switch type {
        case .accessibility:
            openAccessibilitySettings()
        }
    }
}
