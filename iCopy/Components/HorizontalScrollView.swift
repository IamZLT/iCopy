import SwiftUI
import AppKit

// 自定义 NSScrollView 子类，支持鼠标滚轮和拖拽的水平滚动
class CustomHorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        // 将垂直滚轮事件转换为水平滚动
        if let clipView = self.contentView as? NSClipView {
            var newOrigin = clipView.bounds.origin
            newOrigin.x += event.scrollingDeltaY

            // 限制滚动范围
            if let documentView = self.documentView {
                let maxX = max(0, documentView.bounds.width - clipView.bounds.width)
                newOrigin.x = max(0, min(newOrigin.x, maxX))
            }

            clipView.scroll(to: newOrigin)
            self.reflectScrolledClipView(clipView)
        }
    }
}

// 自定义文档视图，支持鼠标拖拽滚动
class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var isDragging = false
    private var lastMouseLocation: NSPoint = .zero
    private var initialScrollOrigin: NSPoint = .zero
    private var dragThreshold: CGFloat = 5.0 // 拖拽阈值，超过这个距离才认为是拖拽

    override func mouseDown(with event: NSEvent) {
        lastMouseLocation = convert(event.locationInWindow, from: nil)
        initialScrollOrigin = self.enclosingScrollView?.contentView.bounds.origin ?? .zero
        isDragging = false
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        let currentLocation = convert(event.locationInWindow, from: nil)
        let deltaX = abs(currentLocation.x - lastMouseLocation.x)

        // 只有当拖拽距离超过阈值时才开始滚动
        if deltaX > dragThreshold {
            isDragging = true
        }

        if isDragging {
            let actualDeltaX = currentLocation.x - lastMouseLocation.x

            if let clipView = self.enclosingScrollView?.contentView as? NSClipView {
                var newOrigin = clipView.bounds.origin
                newOrigin.x = initialScrollOrigin.x - actualDeltaX

                // 限制滚动范围
                let maxX = max(0, self.bounds.width - clipView.bounds.width)
                newOrigin.x = max(0, min(newOrigin.x, maxX))

                clipView.scroll(to: newOrigin)
                self.enclosingScrollView?.reflectScrolledClipView(clipView)
            }
        } else {
            super.mouseDragged(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !isDragging {
            super.mouseUp(with: event)
        }
        isDragging = false
    }
}

// 自定义水平滚动视图，用于解决 macOS 上 ScrollView 滚动问题
struct HorizontalScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> CustomHorizontalScrollView {
        let scrollView = CustomHorizontalScrollView()

        // 隐藏滚动条
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.usesPredominantAxisScrolling = false
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let hostingView = DraggableHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = hostingView

        return scrollView
    }

    func updateNSView(_ nsView: CustomHorizontalScrollView, context: Context) {
        if let hostingView = nsView.documentView as? DraggableHostingView<Content> {
            hostingView.rootView = content
            hostingView.invalidateIntrinsicContentSize()
        }
    }
}
