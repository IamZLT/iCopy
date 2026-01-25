import SwiftUI

// 提示词卡片视图
struct PromptCardView: View {
    let prompt: PromptItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isCopied = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题栏
            HStack(spacing: 10) {
                // 收藏图标
                Button(action: onToggleFavorite) {
                    Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(prompt.isFavorite ? .yellow : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(PlainButtonStyle())

                // 标题
                Text(prompt.title ?? "未命名")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // 分组标签
                if let category = prompt.category {
                    HStack(spacing: 5) {
                        Image(systemName: category.icon ?? "folder")
                            .font(.system(size: 10))
                        Text(category.name ?? "未命名")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(colorFromString(category.color ?? "blue").opacity(0.15))
                    .foregroundColor(colorFromString(category.color ?? "blue"))
                    .cornerRadius(6)
                }
            }

            // 内容预览
            Text(prompt.content ?? "")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 底部操作栏
            HStack(spacing: 12) {
                // 时间信息
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(timeAgoString(from: prompt.updatedAt ?? Date()))
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)

                Spacer()

                // 操作按钮（悬停时显示）
                if isHovered {
                    HStack(spacing: 8) {
                        Button(action: copyToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 12))
                                Text(isCopied ? "已复制" : "复制")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(isCopied ? .green : .accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: onEdit) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 12))
                                Text("编辑")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { showingDeleteAlert = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.circle")
                                    .font(.system(size: 12))
                                Text("删除")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.08) : Color.black.opacity(0.03), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除这个提示词吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    onDelete()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    // 复制到剪贴板
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt.content ?? "", forType: .string)

        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }

    // 颜色转换
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

    // 时间格式化
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)天前"
        } else if hours > 0 {
            return "\(hours)小时前"
        } else if minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}
