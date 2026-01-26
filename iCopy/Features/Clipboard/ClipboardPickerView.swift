import SwiftUI
import CoreData

// 剪贴板选择弹窗（横向卡片布局）
struct ClipboardPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default)
    private var clipboardItems: FetchedResults<ClipboardItem>

    @AppStorage("pickerPosition") private var pickerPosition: String = "bottom"
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0
    @State private var isAnimating: Bool = false
    @State private var eventMonitor: Any?
    @FocusState private var isSearchFocused: Bool
    @Binding var isPresented: Bool
    let onSelect: (ClipboardItem) -> Void

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(clipboardItems.prefix(20)) // 限制显示最近20个
        } else {
            return clipboardItems.filter { item in
                item.content?.localizedCaseInsensitiveContains(searchText) == true
            }.prefix(20).map { $0 }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            searchBar
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.clear)

            // 横向卡片列表
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                horizontalCardList
            }
        }
        .background(Color.clear)
        .offset(x: getAnimationOffset().x, y: getAnimationOffset().y)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnimating)
        .onAppear {
            // 确保焦点不在搜索框上
            isSearchFocused = false

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
        }
        .onDisappear {
            // 移除事件监听
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onChange(of: searchText) { _ in
            // 搜索内容变化时重置选中索引
            selectedIndex = 0
        }
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text(searchText.isEmpty ? "暂无剪贴板历史" : "未找到匹配的内容")
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

            TextField("搜索剪贴板内容...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .focused($isSearchFocused)

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

    // 横向卡片列表
    private var horizontalCardList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 32) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.timestamp) { index, item in
                    ClipboardPickerCardView(
                        item: item,
                        onSelect: {
                            onSelect(item)
                            isPresented = false
                        },
                        isSelected: index == selectedIndex
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                        value: isAnimating
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    // 获取窗口宽度
    private func getWindowWidth() -> CGFloat {
        switch pickerPosition {
        case "left", "right":
            return 300 // 左右侧较窄
        default:
            return NSScreen.main?.frame.width ?? 1200 // 顶部/底部占满宽度
        }
    }

    // 获取窗口高度
    private func getWindowHeight() -> CGFloat {
        switch pickerPosition {
        case "left", "right":
            return NSScreen.main?.frame.height ?? 800 // 左右侧占满高度
        default:
            return 400 // 顶部/底部固定高度（增加以适应更高的卡片）
        }
    }

    // MARK: - 动画偏移量
    private func getAnimationOffset() -> CGPoint {
        if isAnimating {
            return CGPoint(x: 0, y: 0)
        }

        // 根据位置返回初始偏移量
        switch pickerPosition {
        case "top":
            return CGPoint(x: 0, y: -100)
        case "bottom":
            return CGPoint(x: 0, y: 100)
        case "left":
            return CGPoint(x: -100, y: 0)
        case "right":
            return CGPoint(x: 100, y: 0)
        default:
            return CGPoint(x: 0, y: 100)
        }
    }

    // MARK: - Quick Look 预览
    private func showQuickLook(for item: ClipboardItem) {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return }

        switch type {
        case .text:
            // 文本类型创建临时文件预览
            if let content = item.content {
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("clipboard_preview_\(UUID().uuidString).txt")

                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    QuickLookManager.shared.preview(url: fileURL)
                } catch {
                    print("创建临时文本文件失败: \(error)")
                }
            }
        case .image, .file, .folder, .media:
            // 文件类型直接预览
            if let path = item.content {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path) {
                    QuickLookManager.shared.preview(url: url)
                }
            }
        case .other:
            break
        }
    }

    // MARK: - 键盘事件处理
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        // Cmd+/ 聚焦搜索框（避免与系统 Cmd+F 冲突）
        if event.modifierFlags.contains(.command) && event.keyCode == 44 { // / 键
            isSearchFocused = true
            return nil
        }

        // ESC 键始终关闭面板
        if event.keyCode == 53 { // ESC键
            isPresented = false
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

        guard !filteredItems.isEmpty else {
            return event
        }

        switch event.keyCode {
        case 123: // 左箭头
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return nil
        case 124: // 右箭头
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
            }
            return nil
        case 49: // 空格键
            if selectedIndex < filteredItems.count {
                let selectedItem = filteredItems[selectedIndex]
                showQuickLook(for: selectedItem)
            }
            return nil
        case 36: // 回车键
            if selectedIndex < filteredItems.count {
                let selectedItem = filteredItems[selectedIndex]
                onSelect(selectedItem)
                isPresented = false
            }
            return nil
        default:
            return event
        }
    }
}
