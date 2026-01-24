import SwiftUI

// 提示词选择卡片视图
struct PromptPickerCardView: View {
    let prompt: PromptItem
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // 标题栏
                HStack {
                    if prompt.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }

                    Text(prompt.title ?? "未命名")
                        .font(.headline)
                        .foregroundColor(.primary)
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
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
}
