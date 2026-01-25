import SwiftUI
import AppKit

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onDetail: () -> Void

    @State private var isHovered = false
    @State private var isCopied = false
    @State private var showingDeleteAlert = false

    // 是否应该显示缩略图
    private var shouldShowThumbnail: Bool {
        // 所有类型都显示缩略图
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 主内容区域（左边：标签+内容，右边：缩略图）
            mainContentView

            Divider()

            // 底部操作栏
            footerView
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.08) : Color.black.opacity(0.03), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除这个剪切板项目吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    onDelete()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    // 标题栏
    private var headerView: some View {
        HStack(spacing: 10) {
            // 类型标签
            HStack(spacing: 5) {
                Image(systemName: getSystemImage())
                    .font(.system(size: 10))
                Text(getTypeTitle())
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(getTypeColor())
            .cornerRadius(6)

            Spacer()
        }
    }

    // 主内容区域
    private var mainContentView: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左边：标签 + 内容（内容垂直居中）
            VStack(alignment: .leading, spacing: 0) {
                // 标签在顶部
                headerView

                Spacer()

                // 内容在中间（垂直居中）
                contentPreview
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右边：缩略图
            if shouldShowThumbnail {
                thumbnailView
            }
        }
        .frame(minHeight: 60) // 确保至少有缩略图的高度
    }

    // 内容预览
    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let content = item.content {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
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
                    if let path = item.content {
                        mediaThumbnail(path: path)
                    }
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
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .frame(width: 60, height: 60)

            if let content = item.content {
                Text(content)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(8)
                    .padding(4)
                    .frame(width: 60, height: 60)
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
                    .frame(width: 60, height: 60)
                    .cornerRadius(6)
                    .clipped()
            } else {
                placeholderThumbnail(icon: "photo", color: .green)
            }
        }
    }

    // 媒体缩略图
    private func mediaThumbnail(path: String) -> some View {
        placeholderThumbnail(icon: "play.circle", color: .purple)
    }

    // 文件缩略图
    private func fileThumbnail(path: String) -> some View {
        let isFolder = (try? FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeDirectory
        return placeholderThumbnail(icon: isFolder ? "folder" : "doc", color: isFolder ? .blue : .orange)
    }

    // 占位符缩略图
    private func placeholderThumbnail(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
                .frame(width: 60, height: 60)

            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
        }
    }

    // 底部操作栏
    private var footerView: some View {
        HStack(spacing: 12) {
            // 时间信息
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(timeAgoString(from: item.timestamp ?? Date()))
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)

            Spacer()

            // 操作按钮（悬停时显示）
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onDetail) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                            Text("详情")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: handleCopy) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.system(size: 12))
                            Text(isCopied ? "已复制" : "复制")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(isCopied ? .green : .accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showingDeleteAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 12))
                            Text("删除")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - 辅助函数
    private func handleCopy() {
        onCopy()
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }

    private func getSystemImage() -> String {
        guard let type = ClipboardType(rawValue: item.contentType ?? "") else { return "doc" }
        switch type {
        case .text: return "text.quote"
        case .image: return "photo"
        case .file: return "doc"
        case .folder: return "folder"
        case .media: return "play.circle"
        case .other: return "doc"
        }
    }

    private func getTypeTitle() -> String {
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

    private func getTypeColor() -> Color {
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

