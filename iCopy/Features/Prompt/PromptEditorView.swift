import SwiftUI
import CoreData

// 提示词编辑器视图
struct PromptEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let prompt: PromptItem?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PromptCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<PromptCategory>

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var tags: String = ""
    @State private var isFavorite: Bool = false

    var isEditing: Bool {
        prompt != nil
    }

    init(prompt: PromptItem?) {
        self.prompt = prompt
        if let prompt = prompt {
            _title = State(initialValue: prompt.title ?? "")
            _content = State(initialValue: prompt.content ?? "")
            _selectedCategoryID = State(initialValue: prompt.category?.id)
            _tags = State(initialValue: prompt.tags ?? "")
            _isFavorite = State(initialValue: prompt.isFavorite)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text(isEditing ? "编辑提示词" : "添加提示词")
                    .font(.title2)
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

            // 底部按钮栏
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(isEditing ? "保存" : "添加") {
                    savePrompt()
                }
                .keyboardShortcut(.return)
                .disabled(title.isEmpty || content.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
    }

    // 表单内容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题输入
            VStack(alignment: .leading, spacing: 8) {
                Text("标题 *")
                    .font(.headline)
                TextField("请输入提示词标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 分组选择
            VStack(alignment: .leading, spacing: 8) {
                Text("分组")
                    .font(.headline)
                if categories.isEmpty {
                    Text("暂无分组，请先在提示词管理页面创建分组")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "无分组"选项
                            Button(action: { selectedCategoryID = nil }) {
                                Text("无分组")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryID == nil ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // 数据库分组选项
                            ForEach(categories) { category in
                                Button(action: { selectedCategoryID = category.id }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon ?? "folder")
                                            .font(.caption)
                                        Text(category.name ?? "未命名")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryID == category.id ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedCategoryID == category.id ? .white : .primary)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }

            // 内容输入
            VStack(alignment: .leading, spacing: 8) {
                Text("内容 *")
                    .font(.headline)
                TextEditor(text: $content)
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }

            // 标签输入
            VStack(alignment: .leading, spacing: 8) {
                Text("标签（可选）")
                    .font(.headline)
                TextField("用逗号分隔多个标签", text: $tags)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 收藏选项
            Toggle("收藏此提示词", isOn: $isFavorite)
        }
    }

    // 保存提示词
    private func savePrompt() {
        if let existingPrompt = prompt {
            // 更新现有提示词
            existingPrompt.title = title
            existingPrompt.content = content
            existingPrompt.tags = tags
            existingPrompt.isFavorite = isFavorite
            existingPrompt.updatedAt = Date()

            // 更新分组关系
            if let categoryID = selectedCategoryID {
                existingPrompt.category = categories.first(where: { $0.id == categoryID })
            } else {
                existingPrompt.category = nil
            }
        } else {
            // 创建新提示词
            let newPrompt = PromptItem(context: viewContext)
            newPrompt.id = UUID()
            newPrompt.title = title
            newPrompt.content = content
            newPrompt.tags = tags
            newPrompt.isFavorite = isFavorite
            newPrompt.createdAt = Date()
            newPrompt.updatedAt = Date()

            // 设置分组关系
            if let categoryID = selectedCategoryID {
                newPrompt.category = categories.first(where: { $0.id == categoryID })
            }
        }

        try? viewContext.save()
        dismiss()
    }
}
