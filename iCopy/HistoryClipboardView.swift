import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers

struct HistoryClipboardView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100"
    @State private var lastChangeCount: Int = 0
    @State private var eventMonitor: Any?
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default
    ) private var clipboardItems: FetchedResults<ClipboardItem>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text("历史剪切板")
                    .font(.title3)
                    .bold()
            }
            
            // 显示历史记录列表
            List {
                ForEach(clipboardItems, id: \.timestamp) { item in
                    itemView(for: item)
                }
            }
            .frame(height: 150)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            startMonitoringCopyShortcut()
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    private func startMonitoringCopyShortcut() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        if eventMonitor == nil {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 8 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        readClipboardContent()
                    }
                }
            }
        }
    }
    
    private func readClipboardContent() {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // 首先检查是否是文件类型（包括图片、媒体等文件）
            if let urls = pasteboard.propertyList(forType: .fileURL) as? [String] {
                for urlString in urls {
                    if let url = URL(string: urlString) {
                        let type = determineFileType(url: url)
                        saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                    }
                }
            }
            // 检查是否是本地文件拖拽
            else if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                for url in fileURLs {
                    let type = determineFileType(url: url)
                    saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                }
            }
            // 检查是否是图片
            else if let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage] {
                for (index, image) in images.enumerated() {
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData) {
                        let title = "Image \(index + 1)"
                        saveToHistory(type: .image, content: "clipboard_image", title: title)
                    }
                }
            }
            // 最后检查是否是文本
            else if let textContent = pasteboard.string(forType: .string) {
                saveToHistory(type: .text, content: textContent)
            }
        }
    }
    
    private func determineFileType(url: URL) -> ClipboardType {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return .image
        case "mp4", "mov", "avi", "wmv", "mp3", "wav", "m4a", "flac":
            return .media
        default:
            return .file
        }
    }
    
    private func saveToHistory(type: ClipboardType, content: String, title: String? = nil) {
        let maxCount = Int(maxHistoryCount) ?? 100
        
        viewContext.perform {
            // 检查是否已存在相同内容
            let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
            request.predicate = NSPredicate(format: "content == %@ AND contentType == %@", content, type.rawValue)
            request.fetchLimit = 1
            
            do {
                let existingItems = try viewContext.fetch(request)
                if existingItems.isEmpty {
                    let newItem = ClipboardItem(context: viewContext)
                    newItem.content = content
                    newItem.contentType = type.rawValue
                    newItem.timestamp = Date()
                    newItem.title = title
                    
                    if clipboardItems.count >= maxCount {
                        let deleteCount = clipboardItems.count - maxCount + 1
                        
                        for _ in 0..<deleteCount {
                            if let itemToDelete = clipboardItems.last {
                                viewContext.delete(itemToDelete)
                            }
                        }
                    }
                    
                    try viewContext.save()
                }
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
    
    // 修改显示视图，添加点击操作
    private func itemView(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading) {
            if let type = ClipboardType(rawValue: item.contentType ?? "") {
                switch type {
                case .text:
                    Text(item.content ?? "")
                        .lineLimit(2)
                        .onTapGesture {
                            copyToClipboard(content: item.content ?? "")
                        }
                case .image, .file, .media:
                    HStack {
                        Image(systemName: getSystemImage(for: type))
                        Text(item.title ?? getDefaultTitle(for: type))
                    }
                    .onTapGesture {
                        openFile(path: item.content ?? "")
                    }
                case .other:
                    Text(item.content ?? "")
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // 辅助函数
    private func getSystemImage(for type: ClipboardType) -> String {
        switch type {
        case .image:
            return "photo"
        case .file:
            return "doc"
        case .media:
            return "play.circle"
        default:
            return "doc"
        }
    }
    
    private func getDefaultTitle(for type: ClipboardType) -> String {
        switch type {
        case .image:
            return "Image"
        case .file:
            return "File"
        case .media:
            return "Media"
        default:
            return "Item"
        }
    }
    
    // 复制内容到剪贴板
    private func copyToClipboard(content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    // 打开文件
    private func openFile(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
}

struct HistoryClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryClipboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}