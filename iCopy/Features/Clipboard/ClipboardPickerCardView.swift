import SwiftUI
import AppKit

// 剪贴板选择卡片视图（横向布局）
struct ClipboardPickerCardView: View {
    let item: ClipboardItem
    let onSelect: () -> Void
    let isSelected: Bool
    var position: String = "bottom"

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            cardContent
                .scaleEffect(isSelected ? 1.08 : 1.0, anchor: scaleAnchor)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // 根据位置确定放大锚点
    private var scaleAnchor: UnitPoint {
        switch position {
        case "top":
            return .top
        case "left":
            return .leading
        case "right":
            return .trailing
        default: // bottom
            return .bottom
        }
    }

    // 根据位置确定卡片尺寸
    private var cardSize: CGSize {
        switch position {
        case "left", "right":
            return CGSize(width: 220, height: 200) // 左右位置：更宽更矮
        default:
            return CGSize(width: 180, height: 280) // 顶部/底部：原始尺寸
        }
    }

    // 根据位置确定缩略图尺寸
    private var thumbnailSize: CGSize {
        switch position {
        case "left", "right":
            return CGSize(width: 196, height: 120) // 左右位置：更宽更矮
        default:
            return CGSize(width: 156, height: 160) // 顶部/底部：原始尺寸
        }
    }

    // 卡片内容
    private var cardContent: some View {
        VStack(spacing: 12) {
            thumbnailSection
            infoSection
        }
        .padding(12)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }

    // 缩略图区域
    private var thumbnailSection: some View {
        thumbnailView
            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
    }

    // 信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            typeLabel
            contentPreview
            timeLabel
        }
        .frame(width: thumbnailSize.width)
        .padding(.horizontal, 8)
    }

    // 类型标签
    private var typeLabel: some View {
        HStack(spacing: 4) {
            typeIcon.font(.system(size: 10))
            Text(typeTitle).font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(typeColor)
        .cornerRadius(4)
    }

    // 内容预览
    private var contentPreview: some View {
        Group {
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // 时间标签
    private var timeLabel: some View {
        Text(timeAgoString(from: item.timestamp ?? Date()))
            .font(.system(size: 10))
            .foregroundColor(.secondary)
    }

    // 卡片背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.controlBackgroundColor))
    }

    // 卡片边框
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: borderWidth)
    }

    private var borderColor: Color {
        isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.3) : Color.clear)
    }

    private var borderWidth: CGFloat {
        isSelected ? 3 : 1
    }

    private var shadowColor: Color {
        isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1)
    }

    private var shadowRadius: CGFloat {
        isSelected ? 6 : 4
    }

    // 缩略图视图
    private var thumbnailView: some View {
        Group {
            if let type = ClipboardType(rawValue: item.contentType ?? "") {
                switch type {
                case .text:
                    textThumbnail()
                case .image:
                    if let path = item.content {
                        imageThumbnail(path: path)
                    }
                case .media:
                    placeholderThumbnail(icon: "play.circle", color: .purple)
                case .file, .folder:
                    if let path = item.content {
                        fileThumbnail(path: path)
                    }
                case .other:
                    placeholderThumbnail(icon: "doc", color: .gray)
                }
            }
        }
    }

    // 文本缩略图
    private func textThumbnail() -> some View {
        ZStack {
            if let content = item.content {
                Text(content)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(12)
                    .padding(8)
                    .frame(width: 156, height: 160)
            }
        }
    }

    // 图片缩略图
    private func imageThumbnail(path: String) -> some View {
        Group {
            if let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 156, height: 160)
                    .clipped()
            } else {
                placeholderThumbnail(icon: "photo", color: .green)
            }
        }
    }

    // 文件缩略图
    private func fileThumbnail(path: String) -> some View {
        let isFolder = (try? FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeDirectory
        return placeholderThumbnail(icon: isFolder ? "folder" : "doc", color: isFolder ? .blue : .orange)
    }

    // 占位符缩略图
    private func placeholderThumbnail(icon: String, color: Color) -> some View {
        ZStack {
            color.opacity(0.15)
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color)
        }
    }

    // 类型图标
    private var typeIcon: some View {
        Group {
            if let type = ClipboardType(rawValue: item.contentType ?? "") {
                switch type {
                case .text: Image(systemName: "text.quote")
                case .image: Image(systemName: "photo")
                case .file: Image(systemName: "doc")
                case .folder: Image(systemName: "folder")
                case .media: Image(systemName: "play.circle")
                case .other: Image(systemName: "doc")
                }
            }
        }
    }

    // 类型标题
    private var typeTitle: String {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return "其他" }
        switch type {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        case .folder: return "文件夹"
        case .media: return "媒体"
        case .other: return "其他"
        }
    }

    // 类型颜色
    private var typeColor: Color {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return .gray }
        switch type {
        case .text: return Color(red: 0.25, green: 0.47, blue: 0.85)
        case .image: return Color(red: 0.36, green: 0.78, blue: 0.64)
        case .file: return Color(red: 0.95, green: 0.76, blue: 0.29)
        case .folder: return Color(red: 0.5, green: 0.5, blue: 0.9)
        case .media: return Color(red: 0.76, green: 0.34, blue: 0.78)
        case .other: return Color(red: 0.6, green: 0.6, blue: 0.6)
        }
    }

    // 时间格式化
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)天前"
        } else if hours > 0 {
            return "\(hours)小时前"
        } else if minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}
