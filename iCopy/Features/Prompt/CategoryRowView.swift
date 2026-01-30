import SwiftUI

/// 分组行视图
struct CategoryRowView: View {
    let category: PromptCategory
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // 拖动手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: 20)

            // 图标
            ZStack {
                Circle()
                    .fill(colorFromString(category.color ?? "blue").opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: category.icon ?? "folder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorFromString(category.color ?? "blue"))
            }

            // 名称
            Text(category.name ?? "未命名")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            // 数量标签
            HStack(spacing: 4) {
                Text("\(category.prompts?.count ?? 0)")
                    .font(.system(size: 12, weight: .semibold))
                Text("项")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)

            Spacer()

            // 操作按钮（悬停时显示）
            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除这个分组吗？分组下的提示词不会被删除。"),
                primaryButton: .destructive(Text("删除")) {
                    onDelete()
                },
                secondaryButton: .cancel(Text("取消"))
            )
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
