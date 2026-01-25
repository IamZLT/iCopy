import SwiftUI
import CoreData

/// 分组编辑器视图
struct CategoryEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let category: PromptCategory?

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColor: String = "blue"

    let availableIcons = ["folder", "star", "heart", "bookmark", "tag", "flag", "paperclip", "lightbulb"]
    let availableColors = ["blue", "green", "orange", "purple", "red", "pink", "yellow"]

    var isEditing: Bool {
        category != nil
    }

    init(category: PromptCategory?) {
        self.category = category
        if let category = category {
            _name = State(initialValue: category.name ?? "")
            _selectedIcon = State(initialValue: category.icon ?? "folder")
            _selectedColor = State(initialValue: category.color ?? "blue")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text(isEditing ? "编辑分组" : "新建分组")
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
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    formContent
                }
                .padding(24)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // 底部按钮
            footerView
        }
        .frame(width: 480, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // 表单内容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 分组名称
            VStack(alignment: .leading, spacing: 10) {
                Text("分组名称")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                TextField("例如：工作、学习、生活", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // 图标选择
            VStack(alignment: .leading, spacing: 10) {
                Text("图标")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedIcon = icon
                                }
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 52, height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: selectedIcon == icon ? Color.accentColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // 颜色选择
            VStack(alignment: .leading, spacing: 10) {
                Text("颜色")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = color
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(colorFromString(color))
                                        .frame(width: 44, height: 44)

                                    if selectedColor == color {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 44, height: 44)

                                        Circle()
                                            .stroke(colorFromString(color), lineWidth: 2)
                                            .frame(width: 52, height: 52)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // 预览
            VStack(alignment: .leading, spacing: 10) {
                Text("预览")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(colorFromString(selectedColor).opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: selectedIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(colorFromString(selectedColor))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "分组名称" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("这是分组的预览效果")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)

            Button(action: { saveCategory() }) {
                Text(isEditing ? "保存" : "创建")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 80)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(name.isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(8)
                    .shadow(color: name.isEmpty ? Color.clear : Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.return)
            .disabled(name.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // 保存分组
    private func saveCategory() {
        withAnimation {
            if let category = category {
                // 编辑现有分组
                category.name = name
                category.icon = selectedIcon
                category.color = selectedColor
            } else {
                // 创建新分组
                let newCategory = PromptCategory(context: viewContext)
                newCategory.id = UUID()
                newCategory.name = name
                newCategory.icon = selectedIcon
                newCategory.color = selectedColor
                newCategory.createdAt = Date()

                // 设置排序顺序为最后
                let request = NSFetchRequest<PromptCategory>(entityName: "PromptCategory")
                if let count = try? viewContext.count(for: request) {
                    newCategory.sortOrder = Int16(count)
                }
            }

            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("保存分组失败: \(error)")
            }
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
