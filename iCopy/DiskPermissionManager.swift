import Foundation
import AppKit

class DiskPermissionManager {
    static let shared = DiskPermissionManager()
    
    private init() {}
    
    func requestFullDiskAccess() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
    
    func checkFullDiskAccess() -> Bool {
        // 创建一个测试文件路径
        let testPath = "/Library/Application Support/test.txt"
        
        do {
            // 尝试写入一个测试文件
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // 如果成功，立即删除测试文件
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
} 