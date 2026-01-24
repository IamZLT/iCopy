import Foundation
import AppKit
import Cocoa

/// 权限类型枚举
enum PermissionType: String, CaseIterable {
    case accessibility = "辅助功能"
    case fullDiskAccess = "完全磁盘访问"

    var description: String {
        switch self {
        case .accessibility:
            return "用于监听全局快捷键和键盘事件"
        case .fullDiskAccess:
            return "用于访问剪贴板历史和文件操作"
        }
    }

    var icon: String {
        switch self {
        case .accessibility:
            return "hand.raised.fill"
        case .fullDiskAccess:
            return "externaldrive.fill"
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
    @Published var fullDiskAccessStatus: PermissionStatus = .notDetermined

    private init() {
        checkAllPermissions()
    }

    /// 检查所有权限状态
    func checkAllPermissions() {
        accessibilityStatus = checkAccessibilityPermission()
        fullDiskAccessStatus = checkFullDiskAccessPermission()
    }

    /// 检查是否所有必需权限都已授予
    func hasAllRequiredPermissions() -> Bool {
        return accessibilityStatus == .granted && fullDiskAccessStatus == .granted
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

    // MARK: - 完全磁盘访问权限

    /// 检查完全磁盘访问权限
    private func checkFullDiskAccessPermission() -> PermissionStatus {
        let testPath = "/Library/Application Support/.iCopy_permission_test"

        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return .granted
        } catch {
            return .denied
        }
    }

    /// 打开完全磁盘访问设置
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - 通用方法

    /// 打开指定权限的系统设置
    func openSettings(for type: PermissionType) {
        switch type {
        case .accessibility:
            openAccessibilitySettings()
        case .fullDiskAccess:
            openFullDiskAccessSettings()
        }
    }
}
