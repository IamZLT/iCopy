import SwiftUI

/// 权限引导视图
struct PermissionGuideView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerView

            Divider()

            // 内容区域
            contentView

            Divider()

            // 底部按钮
            footerView
        }
        .frame(width: 600, height: 500)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }

    // 顶部标题
    private var headerView: some View {
        HStack {
            Image(systemName: "lock.shield.fill")
                .font(.title)
                .foregroundColor(.blue)
            Text("权限设置")
                .font(.title2)
                .bold()
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // 内容区域
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 说明文字
                Text("iCopy 需要以下权限才能正常工作：")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)

                // 权限列表
                permissionItemView(
                    type: .accessibility,
                    status: permissionManager.accessibilityStatus
                )

                permissionItemView(
                    type: .fullDiskAccess,
                    status: permissionManager.fullDiskAccessStatus
                )
            }
            .padding()
        }
    }

    // 权限项视图
    private func permissionItemView(type: PermissionType, status: PermissionStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge(status)
            }

            if status != .granted {
                Button(action: {
                    permissionManager.openSettings(for: type)
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("打开系统设置")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    // 状态徽章
    private func statusBadge(_ status: PermissionStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status == .granted ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(status == .granted ? "已授权" : "未授权")
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status == .granted ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .foregroundColor(status == .granted ? .green : .red)
        .cornerRadius(12)
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Button("稍后设置") {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Spacer()

            Button("刷新状态") {
                permissionManager.checkAllPermissions()
            }

            if permissionManager.hasAllRequiredPermissions() {
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
