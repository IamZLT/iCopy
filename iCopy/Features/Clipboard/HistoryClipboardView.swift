import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers
import AVFoundation

struct HistoryClipboardView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100"
    @State private var lastChangeCount: Int = 0
    @State private var clipboardTimer: Timer?
    @State private var searchText: String = ""

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default
    ) private var clipboardItems: FetchedResults<ClipboardItem>

    // 过滤后的项目
    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(clipboardItems)
        } else {
            return clipboardItems.filter { item in
                item.content?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 顶部标题栏
            headerView

            // 搜索栏
            searchBar

            // 内容区域
            contentView
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .onAppear {
            startMonitoringCopyShortcut()
        }
        .onDisappear {
            clipboardTimer?.invalidate()
            clipboardTimer = nil
        }
    }

    // 顶部标题栏
    private var headerView: some View {
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
                        onDelete: { deleteItem(item) }
                    )
                }
            }
            .padding(.vertical, 8)
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
            try? viewContext.save()
        }
    }
}
