import SwiftUI

/// 分组行视图
struct CategoryRowView: View {
    let category: PromptCategory
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: category.icon ?? "folder")
                .font(.title3)
                .foregroundColor(colorFromString(category.color ?? "blue"))
                .frame(width: 30)

            // 名称
            Text(category.name ?? "未命名")
                .font(.body)

            Spacer()

            // 提示词数量
            Text("\(category.prompts?.count ?? 0) 个")
                .font(.caption)
                .foregroundColor(.secondary)

            // 编辑按钮
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())

            // 删除按钮
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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
