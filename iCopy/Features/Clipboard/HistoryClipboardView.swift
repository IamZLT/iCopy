import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers
import AVFoundation

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
    
    // 添加一个新的状态变量来存储当前显示的项目
    @State private var visibleItems: [ClipboardItem] = []
    
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
                                currentIndex = (currentIndex - 1 + clipboardItems.count) % clipboardItems.count
                                updateVisibleItems()
                            }
                        case 124: // 右箭头
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentIndex = (currentIndex + 1) % clipboardItems.count
                                updateVisibleItems()
                            }
                        default:
                            break
                        }
                    }
                    
                    HStack(spacing: 25) {
                        ForEach(Array(visibleItems.enumerated()), id: \.element.timestamp) { index, item in
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
                                updateIndex(for: value, geometry: geometry)
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
            if !clipboardItems.isEmpty {
                currentIndex = 0
                updateVisibleItems()
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    // 算HStack的偏移量
    private func calculateHStackOffset(geometry: GeometryProxy) -> CGFloat {
        let itemWidth = getItemWidth(geometry: geometry)
        let spacing: CGFloat = 25
        
        // 始终将当前索引对应的卡片放在中间
        let centeringOffset = geometry.size.width / 2 - itemWidth / 2
        
        // 计算相对于中心的偏移量，固定显示位置
        let relativeOffset = -3 * (itemWidth + spacing)
        
        return centeringOffset + relativeOffset + dragOffset
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
        if index == 3 {
            return 1.08  // 中间位置
        } else if index == 2 || index == 4 {
            return 0.9   // 相邻位置
        } else if index == 1 || index == 5 {
            return 0.8   // 边缘位置
        } else {
            return 0     // 隐藏位置
        }
    }
    
    // 获取垂直移
    private func getOffset(index: Int) -> CGFloat {
        if index == 3 {
            return -15   // 中间位置上移
        } else if index >= 1 && index <= 5 {
            return 0     // 可见位置
        } else {
            return 100   // 隐藏位置
        }
    }
    
    // 获取旋转角度
    private func getRotation(index: Int) -> Double {
        return 0
    }
    
    // 获取Z轴顺序
    private func getZIndex(index: Int) -> Double {
        if index == 3 {
            return 3     // 中间位置最上层
        } else if index == 2 || index == 4 {
            return 2     // 相邻位置次层
        } else if index == 1 || index == 5 {
            return 1     // 边缘位置底层
        } else {
            return 0     // 隐藏位置最底层
        }
    }
    
    // 修改项目视图
    private func itemView(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - 显示类型
            HStack(spacing: 6) {
                // 类型标签容��
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
                        
                case .image:
                    VStack(spacing: 8) {
                        VStack(spacing: 8) {
                            if let path = item.content,
                               let image = NSImage(contentsOfFile: path) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 100)
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(getTypeColor(for: type))
                            }
                            Text(item.title ?? getDefaultTitle(for: type))
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)  // 整个内容区域添加水平内边距
                    }
                    .padding(.vertical, 8)
                    
                case .media:
                    VStack(spacing: 8) {
                        VStack(spacing: 8) {
                            if let path = item.content {
                                if let thumbnail = getMediaThumbnail(path: path) {
                                    Image(nsImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity, maxHeight: 100)
                                } else {
                                    Image(systemName: "play.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(getTypeColor(for: type))
                                        .frame(maxWidth: .infinity, maxHeight: 60)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            } else {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(getTypeColor(for: type))
                                    .frame(maxWidth: .infinity, maxHeight: 60)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            Text(item.title ?? getDefaultTitle(for: type))
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)  // 整个内容区域添加水平内边距
                    }
                    .padding(.vertical, 8)
                    
                case .file, .folder:
                    VStack(spacing: 8) {
                        // 内容区域
                        VStack(spacing: 8) {
                            if let path = item.content {
                                let icon = NSWorkspace.shared.icon(forFile: path)
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 60)
                            } else {
                                Image(systemName: type == .folder ? "folder" : "doc")
                                    .font(.system(size: 32))
                                    .foregroundColor(getTypeColor(for: type))
                            }
                            Text(item.title ?? getDefaultTitle(for: type))
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)  // 整个内容区域添加水平内边距
                    }
                    .padding(.vertical, 8)
                    
                case .other:
                    Text(item.content ?? "")
                }
            }
            
            Spacer()
            
            // Footer - 显示下标和时间
            HStack {
                // 左侧显示下标
                Text("#\(clipboardItems.firstIndex(of: item) ?? 0)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
                
                Spacer()
                
                // 右侧显示时间
                Text(formatDate(item.timestamp ?? Date()))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
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
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)  // 添加底部阴影
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
            return Color(red: 0.95, green: 0.76, blue: 0.29)  // 金黄
        case .folder:
            return Color(red: 0.5, green: 0.5, blue: 0.9)  // 柔和的蓝紫色
        case .media:
            return Color(red: 0.76, green: 0.34, blue: 0.78)  // 紫罗兰色
        case .other:
            return Color(red: 0.6, green: 0.6, blue: 0.6)  // 灰色
        }
    }
    
    // 理点击事件
    private func handleTap(for item: ClipboardItem) {
        if let type = ClipboardType(rawValue: item.contentType ?? "") {
            switch type {
            case .text:
                copyToClipboard(content: item.content ?? "")
            case .image, .file, .media, .folder:
                openFile(path: item.content ?? "")
            case .other:
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
            print("剪贴板发生变化") // 调试输出1
            
            // 检查剪贴板中可用的型
            let types = pasteboard.types ?? []
            print("剪贴板类型: \(types)") // 调试输出2
            
            // 1. 优先检查是否是文件类型（只在包含文件URL类型时检查）
            if types.contains(.fileURL) {
                if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
                    print("检测到文件类型") // 调试输出3
                    for url in fileURLs {
                        let type = determineFileType(url: url)
                        saveToHistory(type: type, content: url.path, title: url.lastPathComponent)
                    }
                    return
                }
            }
            
            // 2. 检查是否是图片
            if types.contains(.tiff) || types.contains(.png) {
                if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
                    print("检测到图片类型") // 调试输出4
                    for (index, image) in images.enumerated() {
                        if let tiffData = image.tiffRepresentation,
                           let bitmapImage = NSBitmapImageRep(data: tiffData) {
                            let title = "Image \(index + 1)"
                            saveToHistory(type: .image, content: "clipboard_image", title: title)
                        }
                    }
                    return
                }
            }
            
            // 3. 检查是否是文本
            if types.contains(.string) {
                print("开始检查文本") // 调试输出5
                if let textContent = pasteboard.string(forType: .string) {
                    print("获取到文本内容: \(textContent)") // 调试输出6
                    if !textContent.isEmpty && !textContent.hasPrefix("file://") {
                        print("保存文本内容") // 调试输出7
                        saveToHistory(type: .text, content: textContent)
                    }
                }
            }
        }
    }
    
    private func determineFileType(url: URL) -> ClipboardType {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return .folder  // 如果是目录，返回文件夹类型
            }
        }
        
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
                if let existingItem = existingItems.first {
                    // 如果存在，更新时间戳
                    existingItem.timestamp = Date()
                } else {
                    // 如果不存在，创建新项
                    let newItem = ClipboardItem(context: viewContext)
                    newItem.content = content
                    newItem.contentType = type.rawValue
                    newItem.timestamp = Date()
                    newItem.title = title
                    
                    // 检查是否超过最大数量
                    if clipboardItems.count >= maxCount {
                        let deleteCount = clipboardItems.count - maxCount + 1
                        
                        for _ in 0..<deleteCount {
                            if let itemToDelete = clipboardItems.last {
                                viewContext.delete(itemToDelete)
                            }
                        }
                    }
                }
                
                try viewContext.save()
                
                // 保存后立即更新UI
                DispatchQueue.main.async {
                    currentIndex = 0  // 将焦点设置到最新项目
                    updateVisibleItems()  // 更新可见项目
                }
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
    
    // 辅助函数
    private func getSystemImage(for type: ClipboardType) -> String {
        switch type {
        case .text:
            return "text.quote"  // 使用系统文本图标
        case .image:
            return "photo"
        case .file:
            return "doc"
        case .folder:
            return "folder"  // 使用系统文件夹图标
        case .media:
            return "play.circle"
        case .other:
            return "doc"
        }
    }
    
    private func getDefaultTitle(for type: ClipboardType) -> String {
        switch type {
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .file:
            return "File"
        case .folder:
            return "Folder"  // 新增文件夹默认标���
        case .media:
            return "Media"
        case .other:
            return "Item"
        }
    }
    
    // 复制内容到板
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
        case .folder:
            return "文件夹"  // 新增文件夹类型标题
        case .media:
            return "媒体"
        case .other:
            return "其他类型"
        }
    }
    
    private func getIndex(for index: Int) -> Int {
        let totalItems = clipboardItems.count
        if totalItems == 0 { return 0 }
        return (index + totalItems) % totalItems
    }
    
    private func updateIndex(for value: DragGesture.Value, geometry: GeometryProxy) {
        let threshold = geometry.size.width * 0.2
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if value.translation.width > threshold {
                // 向右滑动
                currentIndex = (currentIndex - 1 + clipboardItems.count) % clipboardItems.count
                updateVisibleItems()
            } else if value.translation.width < -threshold {
                // 向左滑动
                currentIndex = (currentIndex + 1) % clipboardItems.count
                updateVisibleItems()
            }
            dragOffset = 0
        }
    }
    
    // 更新可见项目数组
    private func updateVisibleItems() {
        let totalItems = clipboardItems.count
        guard totalItems > 0 else {
            visibleItems = []
            return
        }
        
        // 计算需要显示的7个索引
        var indices: [Int] = []
        for offset in -3...3 {
            var index = currentIndex + offset
            if index < 0 {
                index += totalItems
            }
            index = index % totalItems
            indices.append(index)
        }
        
        // 更新可见项目数组
        visibleItems = indices.map { clipboardItems[$0] }
        print("当前显示的索引: \(indices), 焦点位置: 3") // 3是中间位置的索引
    }
    
    // 添加获取媒体缩略图的辅助函数
    private func getMediaThumbnail(path: String) -> NSImage? {
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } catch {
            print("无法生成媒体缩略图: \(error)")
            return nil
        }
    }
}

struct HistoryClipboardView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryClipboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}