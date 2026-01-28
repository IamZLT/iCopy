import SwiftUI
import CoreData

// 提示词选择弹窗（横向卡片布局）
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

    @AppStorage("pickerPosition") private var pickerPosition: String = "bottom"
    @State private var searchText = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var selectedIndex: Int = 0
    @State private var isAnimating: Bool = false
    @State private var isClosing: Bool = false
    @State private var eventMonitor: Any?
    @State private var mouseMonitor: Any?
    @FocusState private var isSearchFocused: Bool
    @State private var shouldPreventAutoFocus: Bool = true
    @Binding var isPresented: Bool
    let onSelect: (PromptItem) -> Void

    var filteredPrompts: [PromptItem] {
        let items = prompts.filter { prompt in
            let matchesSearch = searchText.isEmpty ||
                prompt.title?.localizedCaseInsensitiveContains(searchText) == true ||
                prompt.content?.localizedCaseInsensitiveContains(searchText) == true
            let matchesCategory = selectedCategoryID == nil || prompt.category?.id == selectedCategoryID
            return matchesSearch && matchesCategory
        }
        return Array(items.prefix(20)) // 限制显示最近20个
    }

    var body: some View {
        Group {
            if pickerPosition == "top" {
                topPositionLayout
            } else if pickerPosition == "left" || pickerPosition == "right" {
                sidePositionLayout
            } else {
                bottomPositionLayout
            }
        }
        .background(Color.clear)
        .opacity(isAnimating && !isClosing ? 1.0 : 0.0)
        .offset(x: getLayoutOffset().x, y: getLayoutOffset().y)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnimating)
        .animation(.easeOut(duration: 0.2), value: isClosing)
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanupView()
        }
        .onChange(of: searchText) { _ in
            selectedIndex = 0
        }
    }

    // MARK: - 底部位置布局
    private var bottomPositionLayout: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            searchBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.clear)

            // 分类筛选栏和快捷键说明（同一行）
            HStack(spacing: 16) {
                filterBar
                Spacer()
                shortcutHints
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // 横向卡片列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                horizontalCardList
            }
        }
    }

    // MARK: - 顶部位置布局
    private var topPositionLayout: some View {
        VStack(spacing: 0) {
            // 横向卡片列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                horizontalCardList
            }

            // 分类筛选栏和快捷键说明（同一行）
            HStack(spacing: 16) {
                filterBar
                Spacer()
                shortcutHints
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 底部搜索栏
            searchBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.clear)
        }
    }

    // MARK: - 左右位置布局
    private var sidePositionLayout: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.clear)

            // 卡片和侧边栏（横向排列）
            HStack(spacing: 0) {
                if pickerPosition == "left" {
                    // 左侧：卡片在左，侧边栏在右
                    if filteredPrompts.isEmpty {
                        emptyStateView
                    } else {
                        verticalCardList
                    }
                    sideBar
                } else {
                    // 右侧：侧边栏在左，卡片在右
                    sideBar
                    if filteredPrompts.isEmpty {
                        emptyStateView
                    } else {
                        verticalCardList
                    }
                }
            }
        }
    }

    // 侧边栏（分组和快捷键说明）
    private var sideBar: some View {
        VStack(spacing: 0) {
            // 分类筛选栏（纵向）
            verticalFilterButtons

            Spacer()
                .frame(height: 40)

            Divider()
                .padding(.vertical, 8)

            // 快捷键说明（纵向）
            verticalShortcutHints

            Spacer()
        }
        .frame(width: 70)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text(searchText.isEmpty ? "暂无提示词" : "未找到匹配的提示词")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 搜索栏
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("搜索提示词...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .focused($isSearchFocused)
                .allowsHitTesting(!shouldPreventAutoFocus)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // 分类筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "全部"按钮
                Button(action: { selectedCategoryID = nil }) {
                    HStack(spacing: 4) {
                        Text("0")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(selectedCategoryID == nil ? .white.opacity(0.7) : .secondary)
                        Text("全部")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedCategoryID == nil ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // 动态分类按钮
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    if let name = category.name, let icon = category.icon {
                        categoryButton(
                            title: name,
                            icon: icon,
                            number: "\(index + 1)",
                            categoryID: category.id
                        )
                    }
                }
            }
        }
        .frame(height: 32)
    }

    // 快捷键说明
    private var shortcutHints: some View {
        let isVerticalLayout = pickerPosition == "left" || pickerPosition == "right"
        let arrowKey = isVerticalLayout ? "↑↓" : "←→"

        return HStack(spacing: 12) {
            shortcutHint(key: "0-9", description: "切换分组")
            shortcutHint(key: arrowKey, description: "切换卡片")
            shortcutHint(key: "Space", description: "预览")
            shortcutHint(key: "↵", description: "选择")
            shortcutHint(key: "⌘/", description: "搜索")
            shortcutHint(key: "Esc", description: "退出")
        }
    }

    // 纵向分类按钮（用于侧边栏）
    private var verticalFilterButtons: some View {
        VStack(spacing: 8) {
            // "全部"按钮
            Button(action: { selectedCategoryID = nil }) {
                HStack(spacing: 4) {
                    Text("0")
                        .font(.system(size: 10, weight: .bold))
                    Text("全部")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(selectedCategoryID == nil ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selectedCategoryID == nil ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .fixedSize()
                .rotationEffect(.degrees(-90))
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 50, height: 70)

            // 动态分类按钮
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                if let name = category.name, let icon = category.icon {
                    verticalCategoryButton(
                        title: name,
                        icon: icon,
                        number: "\(index + 1)",
                        categoryID: category.id
                    )
                }
            }
        }
    }

    // 纵向快捷键说明（用于侧边栏）
    private var verticalShortcutHints: some View {
        VStack(alignment: .center, spacing: 8) {
            verticalShortcutHint(key: "0-9", description: "切换分组")
            verticalShortcutHint(key: "↑↓", description: "切换卡片")
            verticalShortcutHint(key: "Space", description: "预览")
            verticalShortcutHint(key: "↵", description: "选择")
            verticalShortcutHint(key: "⌘/", description: "搜索")
            verticalShortcutHint(key: "Esc", description: "退出")
        }
    }

    // 横向卡片列表
    private var horizontalCardList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 32) {
                    ForEach(Array(filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                        PromptPickerCardView(
                            prompt: prompt,
                            onSelect: {
                                onSelect(prompt)
                                closePanel()
                            },
                            isSelected: index == selectedIndex,
                            position: pickerPosition
                        )
                        .id(index)
                        .opacity(isAnimating && !isClosing ? 1.0 : 0.0)
                        .offset(y: getCardOffset(index: index))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                            value: isAnimating
                        )
                        .animation(.easeOut(duration: 0.2), value: isClosing)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .onChange(of: selectedIndex) { newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // 纵向卡片列表
    private var verticalCardList: some View {
        let alignment: HorizontalAlignment = pickerPosition == "left" ? .leading : .trailing

        return ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: alignment, spacing: 24) {
                    ForEach(Array(filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                        PromptPickerCardView(
                            prompt: prompt,
                            onSelect: {
                                onSelect(prompt)
                                closePanel()
                            },
                            isSelected: index == selectedIndex,
                            position: pickerPosition
                        )
                        .id(index)
                        .opacity(isAnimating && !isClosing ? 1.0 : 0.0)
                        .offset(x: getCardOffset(index: index))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                            value: isAnimating
                        )
                        .animation(.easeOut(duration: 0.2), value: isClosing)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onChange(of: selectedIndex) { newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - 辅助方法

    // 设置视图
    private func setupView() {
        // 延迟确保焦点不在搜索框上
        DispatchQueue.main.async {
            isSearchFocused = false
        }

        // 延迟启用搜索框交互，防止自动聚焦
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            shouldPreventAutoFocus = false
        }

        // 启动动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                isAnimating = true
            }
        }

        // 添加事件监听并保存引用
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            return self.handleKeyEvent(event)
        }

        // 添加鼠标点击事件监听（点击外部区域关闭）
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [self] event in
            self.handleMouseClick(event)
        }
    }

    // 清理视图
    private func cleanupView() {
        // 移除事件监听
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    // MARK: - 整体布局偏移量
    private func getLayoutOffset() -> CGPoint {
        // 退出动画
        if isClosing {
            switch pickerPosition {
            case "top":
                return CGPoint(x: 0, y: -50)
            case "bottom":
                return CGPoint(x: 0, y: 50)
            case "left":
                return CGPoint(x: -50, y: 0)
            case "right":
                return CGPoint(x: 50, y: 0)
            default:
                return CGPoint(x: 0, y: 50)
            }
        }

        // 进入动画完成
        if isAnimating {
            return CGPoint(x: 0, y: 0)
        }

        // 初始状态偏移
        switch pickerPosition {
        case "top":
            return CGPoint(x: 0, y: -50)
        case "bottom":
            return CGPoint(x: 0, y: 50)
        case "left":
            return CGPoint(x: -50, y: 0)
        case "right":
            return CGPoint(x: 50, y: 0)
        default:
            return CGPoint(x: 0, y: 50)
        }
    }

    // MARK: - 卡片偏移量
    private func getCardOffset(index: Int) -> CGFloat {
        // 退出动画
        if isClosing {
            switch pickerPosition {
            case "top":
                return -30
            case "bottom":
                return 30
            case "left":
                return -30
            case "right":
                return 30
            default:
                return 30
            }
        }

        // 进入动画完成
        if isAnimating {
            return 0
        }

        // 初始状态偏移
        switch pickerPosition {
        case "top":
            return -20
        case "bottom":
            return 20
        case "left":
            return -20
        case "right":
            return 20
        default:
            return 20
        }
    }

    // MARK: - 关闭面板（带动画）
    private func closePanel() {
        withAnimation(.easeOut(duration: 0.2)) {
            isClosing = true
        }

        // 动画完成后真正关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }

    // MARK: - 处理鼠标点击（点击外部区域关闭）
    private func handleMouseClick(_ event: NSEvent) {
        // 获取当前窗口
        guard let window = NSApp.windows.first(where: { $0.title == "" && $0.level == .floating }) else {
            return
        }

        // 获取鼠标在屏幕上的位置
        let mouseLocation = NSEvent.mouseLocation

        // 检查点击是否在窗口内
        if !window.frame.contains(mouseLocation) {
            closePanel()
        }
    }

    // MARK: - 键盘事件处理
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        // Cmd+/ 聚焦搜索框（避免与系统 Cmd+F 冲突）
        if event.modifierFlags.contains(.command) && event.keyCode == 44 { // / 键
            shouldPreventAutoFocus = false
            DispatchQueue.main.async {
                isSearchFocused = true
            }
            return nil
        }

        // ESC 键始终关闭面板
        if event.keyCode == 53 { // ESC键
            closePanel()
            return nil
        }

        // 如果搜索框获得焦点，回车键取消焦点
        if isSearchFocused {
            if event.keyCode == 36 { // 回车键
                isSearchFocused = false
                return nil
            }
            return event
        }

        // 数字键切换分类（0-9）
        switch event.keyCode {
        case 29: // 0 键
            selectedCategoryID = nil
            return nil
        case 18, 19, 20, 21, 23, 22, 26, 28, 25: // 1-9 键
            let keyMap: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4,
                22: 5, 26: 6, 28: 7, 25: 8
            ]
            if let index = keyMap[event.keyCode], index < categories.count {
                selectedCategoryID = categories[index].id
            }
            return nil
        default:
            break
        }

        guard !filteredPrompts.isEmpty else {
            return event
        }

        // 根据位置使用不同的箭头键
        let isVerticalLayout = pickerPosition == "left" || pickerPosition == "right"

        switch event.keyCode {
        case 123: // 左箭头
            if !isVerticalLayout && selectedIndex > 0 {
                selectedIndex -= 1
            }
            return nil
        case 124: // 右箭头
            if !isVerticalLayout && selectedIndex < filteredPrompts.count - 1 {
                selectedIndex += 1
            }
            return nil
        case 126: // 上箭头
            if isVerticalLayout && selectedIndex > 0 {
                selectedIndex -= 1
            }
            return nil
        case 125: // 下箭头
            if isVerticalLayout && selectedIndex < filteredPrompts.count - 1 {
                selectedIndex += 1
            }
            return nil
        case 49: // 空格键
            if selectedIndex < filteredPrompts.count {
                let selectedPrompt = filteredPrompts[selectedIndex]
                showQuickLook(for: selectedPrompt)
            }
            return nil
        case 36: // 回车键
            if selectedIndex < filteredPrompts.count {
                let selectedPrompt = filteredPrompts[selectedIndex]
                onSelect(selectedPrompt)
                closePanel()
            }
            return nil
        default:
            return event
        }
    }

    // MARK: - Quick Look 预览
    private func showQuickLook(for prompt: PromptItem) {
        // 创建临时文件预览提示词内容
        if let content = prompt.content {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = (prompt.title ?? "prompt") + "_\(UUID().uuidString).txt"
            let fileURL = tempDir.appendingPathComponent(fileName)

            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                QuickLookManager.shared.preview(url: fileURL)
            } catch {
                print("创建临时文件失败: \(error)")
            }
        }
    }

    // MARK: - 分类按钮
    private func categoryButton(title: String, icon: String, number: String, categoryID: UUID?) -> some View {
        Button(action: { selectedCategoryID = categoryID }) {
            HStack(spacing: 4) {
                Text(number)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(selectedCategoryID == categoryID ? .white.opacity(0.7) : .secondary)
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategoryID == categoryID ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(selectedCategoryID == categoryID ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 快捷键提示
    private func shortcutHint(key: String, description: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 纵向分类按钮（用于侧边栏）
    private func verticalCategoryButton(title: String, icon: String, number: String, categoryID: UUID?) -> some View {
        Button(action: { selectedCategoryID = categoryID }) {
            HStack(spacing: 4) {
                Text(number)
                    .font(.system(size: 10, weight: .bold))
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(selectedCategoryID == categoryID ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selectedCategoryID == categoryID ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .fixedSize()
            .rotationEffect(.degrees(-90))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 50, height: 80)
    }

    // MARK: - 纵向快捷键提示（用于侧边栏）
    private func verticalShortcutHint(key: String, description: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .fixedSize()
        .rotationEffect(.degrees(-90))
        .frame(width: 50, height: 70)
    }
}
