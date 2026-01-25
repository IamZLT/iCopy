import SwiftUI

/// 提示词详情视图
struct PromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: PromptItem

    var body: some View {
        ZStack {
            // 背景色
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                headerView

                Divider()

                // 内容区域
                ScrollView {
                    contentView
                        .padding(24)
                }

                Divider()

                // 底部按钮
                footerView
            }
        }
        .frame(width: 700, height: 600)
    }

    // 顶部标题栏
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
            }

            Text("提示词详情")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // 内容视图
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 基本信息
            infoSection

            // 内容展示
            contentSection
        }
    }

    // 基本信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "标题", value: prompt.title ?? "未命名")
                InfoRow(label: "创建时间", value: formatDate(prompt.createdAt ?? Date()))
                InfoRow(label: "更新时间", value: formatDate(prompt.updatedAt ?? Date()))

                if let category = prompt.category {
                    HStack {
                        Text("分组")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)

                        HStack(spacing: 5) {
                            Image(systemName: category.icon ?? "folder")
                                .font(.system(size: 10))
                            Text(category.name ?? "未命名")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(colorFromString(category.color ?? "blue").opacity(0.15))
                        .foregroundColor(colorFromString(category.color ?? "blue"))
                        .cornerRadius(6)

                        Spacer()
                    }
                }

                if let tags = prompt.tags, !tags.isEmpty {
                    InfoRow(label: "标签", value: tags)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // 内容展示区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("内容")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView {
                Text(prompt.content ?? "无内容")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(height: 300)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Text("关闭")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - 辅助函数
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
