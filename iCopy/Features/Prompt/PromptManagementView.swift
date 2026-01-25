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

                Button(action: { showingCategoryManagement = true }) {
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

                Button(action: { showingAddPrompt = true }) {
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

// 自定义 NSScrollView 子类，支持鼠标滚轮和拖拽的水平滚动
class CustomHorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        // 将垂直滚轮事件转换为水平滚动
        if let clipView = self.contentView as? NSClipView {
            var newOrigin = clipView.bounds.origin
            newOrigin.x += event.scrollingDeltaY

            // 限制滚动范围
            if let documentView = self.documentView {
                let maxX = max(0, documentView.bounds.width - clipView.bounds.width)
                newOrigin.x = max(0, min(newOrigin.x, maxX))
            }

            clipView.scroll(to: newOrigin)
            self.reflectScrolledClipView(clipView)
        }
    }
}

// 自定义文档视图，支持鼠标拖拽滚动
class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var isDragging = false
    private var lastMouseLocation: NSPoint = .zero
    private var initialScrollOrigin: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        lastMouseLocation = convert(event.locationInWindow, from: nil)
        initialScrollOrigin = self.enclosingScrollView?.contentView.bounds.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            let currentLocation = convert(event.locationInWindow, from: nil)
            let deltaX = currentLocation.x - lastMouseLocation.x

            if let clipView = self.enclosingScrollView?.contentView as? NSClipView {
                var newOrigin = clipView.bounds.origin
                newOrigin.x = initialScrollOrigin.x - deltaX

                // 限制滚动范围
                let maxX = max(0, self.bounds.width - clipView.bounds.width)
                newOrigin.x = max(0, min(newOrigin.x, maxX))

                clipView.scroll(to: newOrigin)
                self.enclosingScrollView?.reflectScrolledClipView(clipView)
            }
        }
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
}

// 自定义水平滚动视图，用于解决 macOS 上 ScrollView 滚动问题
struct HorizontalScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> CustomHorizontalScrollView {
        let scrollView = CustomHorizontalScrollView()

        // 隐藏滚动条
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.usesPredominantAxisScrolling = false
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let hostingView = DraggableHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = hostingView

        return scrollView
    }

    func updateNSView(_ nsView: CustomHorizontalScrollView, context: Context) {
        if let hostingView = nsView.documentView as? DraggableHostingView<Content> {
            hostingView.rootView = content
            hostingView.invalidateIntrinsicContentSize()
        }
    }
}
