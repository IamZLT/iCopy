import SwiftUI
import AppKit

/// 剪切板详情视图
struct ClipboardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ClipboardItem

    var body: some View {
        ZStack {
            // 背景色
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                headerView

                Divider()

                // 内容区域
                ScrollView {
                    contentView
                        .padding(24)
                }

                Divider()

                // 底部按钮
                footerView
            }
        }
        .frame(width: 700, height: 600)
    }

    // 顶部标题栏
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(getTypeColor().opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: getSystemImage())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(getTypeColor())
            }

            Text("剪切板详情")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // 内容视图
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 基本信息
            infoSection

            // 内容展示
            contentSection
        }
    }

    // 基本信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "类型", value: getTypeTitle())
                InfoRow(label: "时间", value: formatDate(item.timestamp ?? Date()))
                if let title = item.title, !title.isEmpty {
                    InfoRow(label: "标题", value: title)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // 内容展示区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("内容")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Group {
                if item.contentType == "IMAGE" {
                    imageContentView
                } else if item.contentType == "MEDIA" {
                    mediaContentView
                } else {
                    textContentView
                }
            }
        }
    }

    // 文本内容视图
    private var textContentView: some View {
        ScrollView {
            Text(item.content ?? "无内容")
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .frame(height: 300)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // 图片内容视图
    private var imageContentView: some View {
        VStack {
            if let filePath = item.filePath, let image = NSImage(contentsOfFile: filePath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("无法加载图片")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 300)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // 媒体内容视图
    private var mediaContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("媒体文件")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            if let filePath = item.filePath {
                Text(filePath)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Text("关闭")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - 辅助函数
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// 信息行组件
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
