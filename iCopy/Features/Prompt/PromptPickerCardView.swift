import SwiftUI

// 提示词选择卡片视图（横向布局）
struct PromptPickerCardView: View {
    let prompt: PromptItem
    let onSelect: () -> Void
    let isSelected: Bool
    var position: String = "bottom"

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.08 : 1.0, anchor: scaleAnchor)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
            categoryLabel
            titlePreview
            contentPreview
        }
        .frame(width: thumbnailSize.width)
        .padding(.horizontal, 8)
    }

    // 分类标签
    private var categoryLabel: some View {
        Group {
            if let category = prompt.category {
                HStack(spacing: 4) {
                    Image(systemName: category.icon ?? "folder")
                        .font(.system(size: 10))
                    Text(category.name ?? "未命名")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor)
                .cornerRadius(4)
            }
        }
    }

    // 标题预览
    private var titlePreview: some View {
        HStack(spacing: 4) {
            if prompt.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            }
            Text(prompt.title ?? "未命名")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 内容预览
    private var contentPreview: some View {
        Text(prompt.content ?? "")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 缩略图视图
    private var thumbnailView: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 中心图标
            VStack(spacing: 8) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(categoryColor)

                if let category = prompt.category {
                    Text(category.name ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(categoryColor)
                }
            }
        }
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

    // 分类颜色
    private var categoryColor: Color {
        if let category = prompt.category {
            return colorFromString(category.color ?? "blue")
        }
        return .blue
    }

    // 分类图标
    private var categoryIcon: String {
        prompt.category?.icon ?? "text.bubble"
    }

    // 颜色转换
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }
}
