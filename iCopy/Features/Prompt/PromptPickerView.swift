import SwiftUI
import CoreData

// 提示词选择弹窗
struct PromptPickerView: View {
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
    @Binding var isPresented: Bool
    let onSelect: (PromptItem) -> Void

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
            // 顶部标题栏
            HStack {
                Image(systemName: "text.bubble")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("选择提示词")
                    .font(.title3)
                    .bold()
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

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
            .padding()

            Divider()

            // 提示词列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptListView
            }
        }
        .frame(width: 800, height: 600)
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
            Text("请先在提示词管理中添加提示词")
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
                    PromptPickerCardView(prompt: prompt) {
                        onSelect(prompt)
                        isPresented = false
                    }
                }
            }
            .padding()
        }
    }
}
