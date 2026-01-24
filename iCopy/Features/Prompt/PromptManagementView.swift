import SwiftUI
import CoreData

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

    @State private var showingAddPrompt = false
    @State private var editingPrompt: PromptItem?
    @State private var searchText = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var showingCategoryManagement = false

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
            HStack {
                Image(systemName: "text.bubble")
                    .font(.title)
                    .foregroundColor(.green)
                Text("提示词管理")
                    .font(.title3)
                    .bold()
                Spacer()
                Button(action: { showingCategoryManagement = true }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("管理分组")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Button(action: { showingAddPrompt = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加提示词")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()

            // 搜索和筛选栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索提示词...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "全部"按钮
                        Button(action: { selectedCategoryID = nil }) {
                            Text("全部")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategoryID == nil ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // 数据库分组按钮
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
            .padding(.horizontal)
            .padding(.bottom, 10)

            Divider()

            // 提示词列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptListView
            }
        }
        .sheet(isPresented: $showingAddPrompt) {
            PromptEditorView(prompt: nil)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorView(prompt: prompt)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
                .environment(\.managedObjectContext, viewContext)
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
                        onEdit: { editingPrompt = prompt },
                        onDelete: { deletePrompt(prompt) },
                        onToggleFavorite: { toggleFavorite(prompt) }
                    )
                }
            }
            .padding()
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
}
