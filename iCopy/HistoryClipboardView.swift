import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers

struct HistoryClipboardView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100"
    @State private var lastChangeCount: Int = 0
    @State private var eventMonitor: Any?
    @State private var currentIndex: Int = 0  // 当前选中项的索引
    @State private var dragOffset: CGFloat = 0  // 拖动偏移量
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default
    ) private var clipboardItems: FetchedResults<ClipboardItem>
    
    // 更新卡片的圆角大小
    private let cardCornerRadius: CGFloat = 12  // 卡片的圆角
    private let contentCornerRadius: CGFloat = 6  // 内部底色的圆角
    
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
            
            // 轮播视图
            GeometryReader { geometry in
                ZStack {
                    CustomContainerView { event in
                        switch event.keyCode {
                        case 123: // 左箭头
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                }
                            }
                        case 124: // 右箭头
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if currentIndex < clipboardItems.count - 1 {
                                    currentIndex += 1
                                }
                            }
                        default:
                            break
                        }
                    }
                    
                    HStack(spacing: 25) {
                        ForEach(Array(clipboardItems.enumerated()), id: \.element.timestamp) { index, item in
                            itemView(for: item)
                                .frame(width: getItemWidth(geometry: geometry),
                                       height: getItemHeight(geometry: geometry))
                                .scaleEffect(getScale(index: index))
                                .offset(y: getOffset(index: index))
                                .zIndex(getZIndex(index: index))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentIndex)
                        }
                    }
                    .offset(x: calculateHStackOffset(geometry: geometry))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = geometry.size.width * 0.2
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    if value.translation.width > threshold && currentIndex > 0 {
                                        currentIndex -= 1
                                    } else if value.translation.width < -threshold && currentIndex < clipboardItems.count - 1 {
                                        currentIndex += 1
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                }
            }
            .frame(height: 250)
            
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
    
    // 计算HStack的偏移量
    private func calculateHStackOffset(geometry: GeometryProxy) -> CGFloat {
        let itemWidth = getItemWidth(geometry: geometry)
        let totalOffset = -(CGFloat(currentIndex) * (itemWidth + 25))
        return geometry.size.width/2 - itemWidth/2 + totalOffset + dragOffset
    }
    
    // 获取项目宽度
    private func getItemWidth(geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * 0.18
    }
    
    // 获取项目高度
    private func getItemHeight(geometry: GeometryProxy) -> CGFloat {
        return getItemWidth(geometry: geometry) * 1.4
    }
    
    // 获取缩放比例
    private func getScale(index: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        if distance == 0 {
            return 1.08
        } else if distance == 1 {
            return 0.9
        } else {
            return 0.8
        }
    }
    
    // 获取垂直偏移
    private func getOffset(index: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        if distance == 0 {
            return -15
        } else {
            return 0
        }
    }
    
    // 获取旋转角度
    private func getRotation(index: Int) -> Double {
        return 0
    }
    
    // 获取Z轴顺序
    private func getZIndex(index: Int) -> Double {
        return index == currentIndex ? 1 : 0
    }
    
    // 修改项目视图
    private func itemView(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - 显示类型
            HStack(spacing: 6) {
                // 类型标签容器
                HStack(spacing: 4) {
                    Image(systemName: getSystemImage(for: ClipboardType(rawValue: item.contentType ?? "") ?? .other))
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text(getTypeTitle(for: ClipboardType(rawValue: item.contentType ?? "") ?? .other))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: contentCornerRadius)  // 使用内部底色的圆角
                        .fill(getTypeColor(for: ClipboardType(rawValue: item.contentType ?? "") ?? .other))
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content 部分
            if let type = ClipboardType(rawValue: item.contentType ?? "") {
                switch type {
                case .text:
                    Text(item.content ?? "")
                        .font(.system(size: 12))
                        .lineLimit(4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .image, .file, .media:
                    VStack(spacing: 8) {
                        Image(systemName: getSystemImage(for: type))
                            .font(.system(size: 32))
                            .foregroundColor(getTypeColor(for: type))
                        Text(item.title ?? getDefaultTitle(for: type))
                            .font(.system(size: 11))  // 字体小一些
                            .lineLimit(1)  // 一行展示
                            .truncationMode(.tail)  // 超出部分显示省略号
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)  // 水平垂直居中
                    .padding(.vertical, 12)
                case .other:
                    Text(item.content ?? "")
                }
            }
            
            Spacer()
            
            // Footer - 显示时间
            HStack {
                Text(formatDate(item.timestamp ?? Date()))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)  // 使用卡片的圆角
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))  // 使用卡片的圆角
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)  // 使用卡片的圆角
                .stroke(Color(NSColor.separatorColor).opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)  // 添加底部��影
        .onTapGesture {
            handleTap(for: item)
        }
    }
    
    // 更新颜色函数，使颜色更高级
    private func getTypeColor(for type: ClipboardType) -> Color {
        switch type {
        case .text:
            return Color(red: 0.25, green: 0.47, blue: 0.85)  // 深蓝色
        case .image:
            return Color(red: 0.36, green: 0.78, blue: 0.64)  // 绿松石色
        case .file:
            return Color(red: 0.95, green: 0.76, blue: 0.29)  // 金黄色
        case .media:
            return Color(red: 0.76, green: 0.34, blue: 0.78)  // 紫罗兰色
        case .other:
            return Color(red: 0.6, green: 0.6, blue: 0.6)  // 灰色
        }
    }
    
    // 处理点击事件
    private func handleTap(for item: ClipboardItem) {
        if let type = ClipboardType(rawValue: item.contentType ?? "") {
            switch type {
            case .text:
                copyToClipboard(content: item.content ?? "")
            case .image, .file, .media:
                openFile(path: item.content ?? "")
            default:
                break
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
            
            // 首先检查是否是文本内容
            if let textContent = pasteboard.string(forType: .string) {
                // 检查是否是文件路径
                if !textContent.hasPrefix("file://") {
                    saveToHistory(type: .text, content: textContent)
                    return  // 如果是普通文本，保存后直接返回
                }
            }
            
            // 然后检查是否是文件类型
            if let urls = pasteboard.propertyList(forType: .fileURL) as? [String] {
                for urlString in urls {
                    if let url = URL(string: urlString) {
                        let type = determineFileType(url: url)
                        saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                    }
                }
                return  // 如果是文件，保存后返回
            }
            
            // 检查是否是文件拖拽
            if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                for url in fileURLs {
                    let type = determineFileType(url: url)
                    saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                }
                return  // 如果是拖拽文件，保存后返回
            }
            
            // 最后检查是否是图片
            if let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage] {
                for (index, image) in images.enumerated() {
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData) {
                        let title = "Image \(index + 1)"
                        saveToHistory(type: .image, content: "clipboard_image", title: title)
                    }
                }
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
    
    // 复制内容到贴板
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
    
    // 添加新的辅助函数
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func getTypeTitle(for type: ClipboardType) -> String {
        switch type {
        case .text:
            return "文本"
        case .image:
            return "图片"
        case .file:
            return "文件"
        case .media:
            return "媒体"
        case .other:
            return "其他类型"
        }
    }
}

struct HistoryClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryClipboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}