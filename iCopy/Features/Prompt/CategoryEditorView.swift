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
            // 表单内容
            VStack(alignment: .leading, spacing: 16) {
                formContent
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)

            // 底部按钮
            footerView
                .background(Color(NSColor.windowBackgroundColor))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 480, height: 380)
    }
    // 表单内容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分组名称
            VStack(alignment: .leading, spacing: 6) {
                Text("分组名称")
                    .font(.system(size: 13, weight: .semibold))
                TextField("例如：工作、学习、生活", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }

            // 图标和颜色选择（合并为一行）
            HStack(alignment: .top, spacing: 16) {
                // 图标选择
                VStack(alignment: .leading, spacing: 6) {
                    Text("图标")
                        .font(.system(size: 13, weight: .semibold))
                    HorizontalScrollView {
                        HStack(spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIcon = icon
                                    }
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(height: 40)
                }

                // 颜色选择
                VStack(alignment: .leading, spacing: 6) {
                    Text("颜色")
                        .font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 8) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = color
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(colorFromString(color))
                                        .frame(width: 32, height: 32)
                                    
                                    if selectedColor == color {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 32, height: 32)
                                        
                                        Circle()
                                            .stroke(colorFromString(color), lineWidth: 1.5)
                                            .frame(width: 38, height: 38)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // 预览
            VStack(alignment: .leading, spacing: 6) {
                Text("预览")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorFromString(selectedColor).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: selectedIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorFromString(selectedColor))
                    }
                    
                    Text(name.isEmpty ? "分组名称" : name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack(spacing: 10) {
            Spacer()

            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(minWidth: 70)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(7)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)

            Button(action: { saveCategory() }) {
                Text(isEditing ? "保存" : "创建")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 70)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(7)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    .opacity(name.isEmpty ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.return)
            .disabled(name.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 40)
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
