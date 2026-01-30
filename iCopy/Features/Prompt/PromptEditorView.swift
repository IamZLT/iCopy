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
            // 表单内容
            VStack(alignment: .leading, spacing: 16) {
                formContent
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // 底部按钮栏
            footerView
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 600, height: 500)
    }
    // 底部按钮栏
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

            Button(action: { savePrompt() }) {
                Text(isEditing ? "保存" : "添加")
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
                    .opacity(title.isEmpty || content.isEmpty ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.return)
            .disabled(title.isEmpty || content.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // 表单内容
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题输入
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("标题")
                        .font(.system(size: 13, weight: .semibold))
                    Text("*")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
                TextField("请输入提示词标题", text: $title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(title.isEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }

            // 分组选择
            VStack(alignment: .leading, spacing: 6) {
                Text("分组")
                    .font(.system(size: 13, weight: .semibold))
                if categories.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("暂无分组")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                } else {
                    HorizontalScrollView {
                        HStack(spacing: 8) {
                            Button(action: { selectedCategoryID = nil }) {
                                Text("无分组")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryID == nil ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())

                            ForEach(categories) { category in
                                Button(action: { selectedCategoryID = category.id }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon ?? "folder")
                                            .font(.system(size: 10))
                                        Text(category.name ?? "未命名")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryID == category.id ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedCategoryID == category.id ? .white : .primary)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(height: 32)
                }
            }

            // 内容输入
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("内容")
                        .font(.system(size: 13, weight: .semibold))
                    Text("*")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("请输入提示词内容...")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $content)
                        .font(.system(size: 13))
                        .frame(height: 180)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(content.isEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
            }

            // 标签输入和收藏选项（合并为一行）
            HStack(spacing: 12) {
                // 标签输入
                VStack(alignment: .leading, spacing: 6) {
                    Text("标签（可选）")
                        .font(.system(size: 13, weight: .semibold))
                    TextField("用逗号分隔", text: $tags)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }

                // 收藏选项
                VStack(alignment: .leading, spacing: 6) {
                    Text("收藏")
                        .font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 8) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(isFavorite ? .yellow : .gray)

                        Toggle("", isOn: $isFavorite)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                }
                .frame(width: 120)
            }
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
