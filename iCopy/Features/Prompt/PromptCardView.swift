import SwiftUI

// 提示词卡片视图
struct PromptCardView: View {
    let prompt: PromptItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                // 收藏图标
                Button(action: onToggleFavorite) {
                    Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                        .foregroundColor(prompt.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                // 标题
                Text(prompt.title ?? "未命名")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // 分组标签
                if let category = prompt.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon ?? "folder")
                            .font(.caption2)
                        Text(category.name ?? "未命名")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorFromString(category.color ?? "blue").opacity(0.2))
                    .foregroundColor(colorFromString(category.color ?? "blue"))
                    .cornerRadius(4)
                }
            }

            // 内容预览
            Text(prompt.content ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 底部操作栏
            HStack {
                // 时间信息
                Text(timeAgoString(from: prompt.updatedAt ?? Date()))
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                // 复制按钮
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "已复制" : "复制")
                    }
                    .font(.caption)
                    .foregroundColor(isCopied ? .green : .blue)
                }
                .buttonStyle(PlainButtonStyle())

                // 编辑按钮
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("编辑")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                // 删除按钮
                Button(action: { showingDeleteAlert = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("删除")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
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
