import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers
import AVFoundation

// Alert 类型枚举
enum ClipboardAlertType: Identifiable {
    case clear
    case delete(ClipboardItem)

    var id: String {
        switch self {
        case .clear: return "clear"
        case .delete(let item): return "delete_\(item.timestamp?.timeIntervalSince1970 ?? 0)"
        }
    }
}

struct HistoryClipboardView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100"
    @State private var lastChangeCount: Int = 0
    @State private var clipboardTimer: Timer?
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var activeAlert: ClipboardAlertType? = nil

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default
    ) private var clipboardItems: FetchedResults<ClipboardItem>

    // 过滤后的项目
    private var filteredItems: [ClipboardItem] {
        clipboardItems.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.content?.localizedCaseInsensitiveContains(searchText) == true
            let matchesCategory = selectedCategory == nil || item.contentType == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("历史剪切板")
                        .font(.system(size: 22, weight: .bold))
                    Text("\(clipboardItems.count) 个项目")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { activeAlert = .clear }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13))
                        Text("清空")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.red)
                    .cornerRadius(8)
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
                .padding(.horizontal, 24)

            // 内容区域
            contentView
        }
        .onAppear {
            startMonitoringCopyShortcut()
        }
        .onDisappear {
            clipboardTimer?.invalidate()
            clipboardTimer = nil
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .clear:
                return Alert(
                    title: Text("确认清空"),
                    message: Text("确定要清空所有剪切板历史记录吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("清空")) {
                        clearAllClipboard()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            case .delete(let item):
                return Alert(
                    title: Text("确认删除"),
                    message: Text("确定要删除这个剪切板项目吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        deleteItem(item)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }

    // 搜索栏
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("搜索剪切板内容...", text: $searchText)
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
                Button(action: { selectedCategory = nil }) {
                    Text("全部")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // 文本
                categoryButton(title: "文本", icon: "text.quote", type: .text)

                // 图片
                categoryButton(title: "图片", icon: "photo", type: .image)

                // 文件
                categoryButton(title: "文件", icon: "doc", type: .file)

                // 文件夹
                categoryButton(title: "文件夹", icon: "folder", type: .folder)

                // 媒体
                categoryButton(title: "媒体", icon: "play.circle", type: .media)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 38)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // 内容区域
    private var contentView: some View {
        Group {
            if clipboardItems.isEmpty {
                emptyStateView
            } else if filteredItems.isEmpty {
                noResultsView
            } else {
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("暂无剪切板历史")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)

            Text("复制内容后会自动保存到这里")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 无搜索结果视图
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("未找到匹配的内容")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 列表视图
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredItems, id: \.timestamp) { item in
                    ClipboardItemCard(
                        item: item,
                        onCopy: { copyToClipboard(item) },
                        onDelete: {
                            activeAlert = .delete(item)
                        },
                        onDetail: {
                            previewClipboardItem(item)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - 剪切板监听
    private func startMonitoringCopyShortcut() {
        lastChangeCount = NSPasteboard.general.changeCount

        // 启动定时器，每0.5秒检查一次剪切板
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkClipboardChanges()
        }
    }

    private func checkClipboardChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // 如果剪切板内容发生变化
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            readClipboardContent()
        }
    }

    private func readClipboardContent() {
        let pasteboard = NSPasteboard.general

        // 检查是否有文件路径
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            for fileURL in fileURLs {
                let path = fileURL.path
                let type = determineFileType(path: path)
                saveToHistory(content: path, type: type)
            }
            return
        }

        // 检查是否有图片
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "clipboard_image_\(Date().timeIntervalSince1970).png"
                let fileURL = tempDir.appendingPathComponent(fileName)

                do {
                    try pngData.write(to: fileURL)
                    saveToHistory(content: fileURL.path, type: .image)
                } catch {
                    print("保存图片失败: \(error)")
                }
            }
            return
        }

        // 检查是否有文本
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            saveToHistory(content: text, type: .text)
            return
        }
    }

    // MARK: - 辅助函数
    private func determineFileType(path: String) -> ClipboardType {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)

        if !exists {
            return .other
        }

        if isDirectory.boolValue {
            return .folder
        }

        let fileExtension = (path as NSString).pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        let mediaExtensions = ["mp4", "mov", "avi", "mkv", "mp3", "wav", "m4a", "flac"]

        if imageExtensions.contains(fileExtension) {
            return .image
        } else if mediaExtensions.contains(fileExtension) {
            return .media
        } else {
            return .file
        }
    }

    private func saveToHistory(content: String, type: ClipboardType) {
        // 检查是否已存在相同内容
        let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "content == %@", content)
        fetchRequest.fetchLimit = 1

        do {
            let existingItems = try viewContext.fetch(fetchRequest)
            if !existingItems.isEmpty {
                // 如果已存在，更新时间戳
                existingItems[0].timestamp = Date()
                try viewContext.save()
                return
            }
        } catch {
            print("检查重复项失败: \(error)")
        }

        // 创建新项目
        let newItem = ClipboardItem(context: viewContext)
        newItem.content = content
        newItem.contentType = type.rawValue
        newItem.timestamp = Date()

        do {
            try viewContext.save()

            // 检查是否超过最大历史数量
            if let maxCount = Int(maxHistoryCount), clipboardItems.count > maxCount {
                let itemsToDelete = clipboardItems.count - maxCount
                for i in 0..<itemsToDelete {
                    let index = clipboardItems.count - 1 - i
                    if index >= 0 && index < clipboardItems.count {
                        viewContext.delete(clipboardItems[index])
                    }
                }
                try viewContext.save()
            }
        } catch {
            print("保存剪切板历史失败: \(error)")
        }
    }

    // 预览剪切板项目
    private func previewClipboardItem(_ item: ClipboardItem) {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return }

        switch type {
        case .text:
            // 文本类型：创建临时文件并预览
            if let content = item.content {
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "clipboard_text_\(Date().timeIntervalSince1970).txt"
                let fileURL = tempDir.appendingPathComponent(fileName)

                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    QuickLookManager.shared.preview(url: fileURL)
                } catch {
                    print("创建临时文本文件失败: \(error)")
                }
            }
        case .image, .file, .media, .folder:
            // 文件类型：直接预览文件路径
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

    // MARK: - 操作函数
    private func copyToClipboard(_ item: ClipboardItem) {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch type {
        case .text:
            pasteboard.setString(item.content ?? "", forType: .string)
        case .image, .file, .media, .folder:
            if let path = item.content {
                let url = URL(fileURLWithPath: path)
                pasteboard.writeObjects([url as NSPasteboardWriting])
            }
        case .other:
            break
        }
    }

    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            viewContext.delete(item)

            do {
                try viewContext.save()
                print("✅ 成功删除剪切板项目")
            } catch {
                print("❌ 删除剪切板项目失败: \(error.localizedDescription)")
                // 如果保存失败，回滚更改
                viewContext.rollback()
            }
        }
    }

    // 清空所有剪切板历史
    private func clearAllClipboard() {
        withAnimation {
            for item in clipboardItems {
                viewContext.delete(item)
            }
            try? viewContext.save()
        }
    }

    // 分类按钮辅助函数
    private func categoryButton(title: String, icon: String, type: ClipboardType) -> some View {
        Button(action: { selectedCategory = type.rawValue }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategory == type.rawValue ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(selectedCategory == type.rawValue ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
