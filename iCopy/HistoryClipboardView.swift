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
            
            // 检查并处理不同类型的内容
            if let textContent = pasteboard.string(forType: .string) {
                // 处理文本类型
                saveToHistory(type: .text, content: textContent)
            } else if let imageData = pasteboard.data(forType: .tiff),
                      let image = NSImage(data: imageData) {
                // 处理图片类型
                if let url = saveImageToFile(image: image) {
                    saveToHistory(type: .image, content: url.path, title: "Image")
                }
            } else if let urls = pasteboard.propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? [String] {
                // 处理文件类型
                for urlString in urls {
                    if let url = URL(string: urlString.removingPercentEncoding ?? urlString) {
                        let type = determineFileType(url: url)
                        let path = url.path
                        print("File path: \(path)") // 调试用
                        saveToHistory(type: type, content: path, title: url.lastPathComponent)
                    }
                }
            } else {
                // 尝试其他方式获取文件URL
                if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                    for url in fileURLs {
                        let type = determineFileType(url: url)
                        print("File path (alternative): \(url.path)") // 调试用
                        saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                    }
                }
            }
        }
    }
    
    private func determineFileType(url: URL) -> ClipboardType {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return .image
        case "mp4", "mov", "avi", "wmv", "mp3", "wav", "m4a":
            return .media
        default:
            return .file
        }
    }
    
    private func saveImageToFile(image: NSImage) -> URL? {
        let fileManager = FileManager.default
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let iCopyDirectory = applicationSupport.appendingPathComponent("iCopy/Images")
        
        do {
            try fileManager.createDirectory(at: iCopyDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let fileName = "\(UUID().uuidString).png"
            let fileURL = iCopyDirectory.appendingPathComponent(fileName)
            
            // 将 NSImage 转换为 PNG 数据
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                
                try pngData.write(to: fileURL)
                return fileURL
            }
        } catch {
            print("保存图片失败: \(error.localizedDescription)")
        }
        
        return nil
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
    
    // 添加一个用于显示不同类型内容的视图
    private func itemView(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading) {
            if let type = ClipboardType(rawValue: item.contentType ?? "") {
                switch type {
                case .text:
                    Text(item.content ?? "")
                        .lineLimit(2)
                case .image:
                    if let path = item.content,
                       let url = URL(string: path),
                       let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                    }
                case .file, .media:
                    HStack {
                        Image(systemName: type == .media ? "play.circle" : "doc")
                        Text(item.title ?? item.content ?? "")
                    }
                case .other:
                    Text(item.content ?? "")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryClipboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}