import SwiftUI

/// 分组行视图
struct CategoryRowView: View {
    let category: PromptCategory
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(colorFromString(category.color ?? "blue").opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: category.icon ?? "folder")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colorFromString(category.color ?? "blue"))
            }

            // 名称和数量
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "未命名")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(category.prompts?.count ?? 0) 个提示词")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮（悬停时显示）
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.scale.combined(with: .opacity))
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
        .shadow(color: isHovered ? Color.black.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
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
