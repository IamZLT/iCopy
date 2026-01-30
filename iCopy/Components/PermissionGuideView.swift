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

            // 内容区域
            contentView

            // 底部按钮
            footerView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 500, height: 320)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }

    // 顶部标题
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }

            Text("权限设置")
                .font(.system(size: 17, weight: .bold))

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // 内容区域
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 说明文字
                Text("iCopy 需要以下权限才能正常工作：")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                // 权限列表
                permissionItemView(
                    type: .accessibility,
                    status: permissionManager.accessibilityStatus
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // 权限项视图
    private func permissionItemView(type: PermissionType, status: PermissionStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: type.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    Text(type.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusBadge(status)
            }

            if status != .granted {
                Button(action: {
                    permissionManager.openSettings(for: type)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .font(.system(size: 11))
                        Text("打开系统设置")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // 状态徽章
    private func statusBadge(_ status: PermissionStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status == .granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 11))
            Text(status == .granted ? "已授权" : "未授权")
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status == .granted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
        .foregroundColor(status == .granted ? .green : .orange)
        .cornerRadius(10)
    }

    // 底部按钮
    private var footerView: some View {
        HStack(spacing: 10) {
            Button(action: { dismiss() }) {
                Text("稍后设置")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(7)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)

            Spacer()

            Button(action: {
                permissionManager.checkAllPermissions()
            }) {
                Text("刷新状态")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(7)
            }
            .buttonStyle(PlainButtonStyle())

            if permissionManager.hasAllRequiredPermissions() {
                Button(action: { dismiss() }) {
                    Text("完成")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 80)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(7)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.return)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
