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
                Text(isEditing ? "编辑分组" : "添加分组")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    formContent
                }
                .padding()
            }

            Divider()

            // 底部按钮
            footerView
        }
        .frame(width: 400, height: 450)
    }

    // 表单内容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 分组名称
            VStack(alignment: .leading, spacing: 8) {
                Text("分组名称")
                    .font(.headline)
                TextField("请输入分组名称", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 图标选择
            VStack(alignment: .leading, spacing: 8) {
                Text("选择图标")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("选择颜色")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // 预览
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.headline)
                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .font(.title)
                        .foregroundColor(colorFromString(selectedColor))
                        .frame(width: 50, height: 50)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    Text(name.isEmpty ? "分组名称" : name)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Spacer()
            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Button(isEditing ? "保存" : "添加") {
                saveCategory()
            }
            .keyboardShortcut(.return)
            .disabled(name.isEmpty)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
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
