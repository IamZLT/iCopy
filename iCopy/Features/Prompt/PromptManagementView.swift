import SwiftUI
import CoreData
import AppKit

struct PromptManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PromptItem.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \PromptItem.updatedAt, ascending: false)
        ],
        animation: .default)
    private var prompts: FetchedResults<PromptItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PromptCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<PromptCategory>

    @State private var searchText = ""
    @State private var selectedCategoryID: UUID? = nil

    var filteredPrompts: [PromptItem] {
        prompts.filter { prompt in
            let matchesSearch = searchText.isEmpty ||
                prompt.title?.localizedCaseInsensitiveContains(searchText) == true ||
                prompt.content?.localizedCaseInsensitiveContains(searchText) == true
            let matchesCategory = selectedCategoryID == nil || prompt.category?.id == selectedCategoryID
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("提示词管理")
                        .font(.system(size: 22, weight: .bold))
                    Text("\(prompts.count) 个提示词")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    WindowManager.shared.showWindow(
                        id: "categoryManagement",
                        title: "分组管理",
                        size: NSSize(width: 500, height: 400),
                        content: CategoryManagementView()
                            .environment(\.managedObjectContext, viewContext)
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 13))
                        Text("管理分组")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    WindowManager.shared.showWindow(
                        id: "addPrompt",
                        title: "添加提示词",
                        size: NSSize(width: 600, height: 500),
                        content: PromptEditorView(prompt: nil)
                            .environment(\.managedObjectContext, viewContext)
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("添加提示词")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // 搜索栏
            searchBar

            // 筛选栏
            filterBar

            Divider()
                .padding(.horizontal, 24) // 与搜索框和筛选栏保持一致的宽度

            // 提示词列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptListView
            }
        }
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无提示词")
                .font(.title2)
                .foregroundColor(.gray)
            Text("点击右上角按钮添加您的第一个提示词")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 提示词列表视图
    private var promptListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPrompts) { prompt in
                    PromptCardView(
                        prompt: prompt,
                        onEdit: {
                            WindowManager.shared.showWindow(
                                id: "editPrompt_\(prompt.id?.uuidString ?? "")",
                                title: "编辑提示词",
                                size: NSSize(width: 600, height: 500),
                                content: PromptEditorView(prompt: prompt)
                                    .environment(\.managedObjectContext, viewContext)
                            )
                        },
                        onDelete: { deletePrompt(prompt) },
                        onToggleFavorite: { toggleFavorite(prompt) },
                        onDetail: {
                            previewPrompt(prompt)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // 预览提示词
    private func previewPrompt(_ prompt: PromptItem) {
        // 创建临时文件来预览提示词内容
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "prompt_\(prompt.title ?? "untitled")_\(Date().timeIntervalSince1970).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // 构建预览内容
        var previewContent = ""
        previewContent += "标题: \(prompt.title ?? "未命名")\n"
        previewContent += "创建时间: \(formatDate(prompt.createdAt ?? Date()))\n"
        previewContent += "更新时间: \(formatDate(prompt.updatedAt ?? Date()))\n"

        if let category = prompt.category {
            previewContent += "分组: \(category.name ?? "未命名")\n"
        }

        if let tags = prompt.tags, !tags.isEmpty {
            previewContent += "标签: \(tags)\n"
        }

        previewContent += "\n" + String(repeating: "-", count: 50) + "\n\n"
        previewContent += prompt.content ?? "无内容"

        do {
            try previewContent.write(to: fileURL, atomically: true, encoding: .utf8)
            QuickLookManager.shared.preview(url: fileURL)
        } catch {
            print("创建临时提示词文件失败: \(error)")
        }
    }

    // 删除提示词
    private func deletePrompt(_ prompt: PromptItem) {
        withAnimation {
            viewContext.delete(prompt)
            try? viewContext.save()
        }
    }

    // 切换收藏状态
    private func toggleFavorite(_ prompt: PromptItem) {
        withAnimation {
            prompt.isFavorite.toggle()
            prompt.updatedAt = Date()
            try? viewContext.save()
        }
    }

    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    // 搜索栏
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("搜索提示词...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 24)
    }

    // 筛选栏
    private var filterBar: some View {
        HorizontalScrollView {
            HStack(spacing: 8) {
                // "全部"按钮
                Button(action: { selectedCategoryID = nil }) {
                    Text("全部")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategoryID == nil ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // 数据库分组按钮
                ForEach(categories) { category in
                    Button(action: { selectedCategoryID = category.id }) {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon ?? "folder")
                                .font(.system(size: 11))
                            Text(category.name ?? "未命名")
                                .font(.system(size: 13, weight: .medium))
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
        .padding(.horizontal, 24)
        .frame(height: 38)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}
