import SwiftUI

// 剪贴板选择卡片视图
struct ClipboardPickerCardView: View {
    let item: ClipboardItem
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 类型图标
                typeIcon
                    .font(.title2)
                    .foregroundColor(typeColor)
                    .frame(width: 40)

                // 内容区域
                VStack(alignment: .leading, spacing: 4) {
                    if let title = item.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    if let content = item.content, !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // 时间信息
                Text(timeAgoString(from: item.timestamp ?? Date()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(isHovered ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // 类型图标
    private var typeIcon: some View {
        Group {
            switch item.contentType {
            case "TEXT":
                Image(systemName: "doc.text")
            case "IMAGE":
                Image(systemName: "photo")
            case "FILE":
                Image(systemName: "doc")
            case "FOLDER":
                Image(systemName: "folder")
            default:
                Image(systemName: "doc.on.clipboard")
            }
        }
    }

    // 类型颜色
    private var typeColor: Color {
        switch item.contentType {
        case "TEXT": return .blue
        case "IMAGE": return .green
        case "FILE": return .orange
        case "FOLDER": return .purple
        default: return .gray
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
