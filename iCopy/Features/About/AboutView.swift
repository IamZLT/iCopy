import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            headerView
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, 24)

            // 内容区域
            ScrollView {
                VStack(spacing: 20) {
                    // 应用信息
                    appInfoSection

                    // GitHub 开源信息
                    githubSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - 顶部标题
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("软件说明")
                    .font(.system(size: 22, weight: .bold))
                Text("了解 iCopy 的功能和使用方法")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - 应用信息
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("应用信息")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                AboutInfoRow(icon: "app.badge", iconColor: .blue, title: "应用名称", value: "iCopy")
                Divider().padding(.leading, 40)
                AboutInfoRow(icon: "number", iconColor: .green, title: "版本号", value: "1.0.0")
                Divider().padding(.leading, 40)
                AboutInfoRow(icon: "calendar", iconColor: .orange, title: "发布日期", value: "2026年1月")
                Divider().padding(.leading, 40)
                AboutInfoRow(icon: "lock.shield", iconColor: .purple, title: "数据存储", value: "本地存储")
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - GitHub 开源信息
    private var githubSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("开源项目")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                // GitHub 仓库链接
                GitHubLinkCard()

                // 问题反馈和 Star 支持（左右排列）
                HStack(spacing: 12) {
                    // 问题反馈
                    GitHubActionCard(
                        icon: "exclamationmark.bubble",
                        iconColor: .orange,
                        title: "遇到问题？",
                        description: "如果您在使用过程中遇到任何问题，欢迎在 GitHub 上提交 Issue",
                        actionText: "提交 Issue"
                    )

                    // Star 支持
                    GitHubActionCard(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "觉得不错？",
                        description: "如果这个项目对您有帮助，欢迎在 GitHub 上给个 Star 支持一下",
                        actionText: "给个 Star"
                    )
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - 信息行组件
struct AboutInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - GitHub 链接卡片
struct GitHubLinkCard: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if let url = URL(string: "https://github.com/IamZLT/iCopy") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("GitHub 仓库")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("https://github.com/IamZLT/iCopy")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.blue)
                }

                Spacer()

                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isHovered ? .blue : .secondary)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isHovered ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - GitHub 操作卡片
struct GitHubActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let actionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    if let url = URL(string: "https://github.com/IamZLT/iCopy") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(actionText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
