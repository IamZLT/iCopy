import SwiftUI
import Quartz

/// Quick Look 预览管理器
class QuickLookManager: NSObject {
    static let shared = QuickLookManager()

    private var previewPanel: QLPreviewPanel?
    private var currentURLs: [URL] = []

    /// 预览文件
    func preview(url: URL) {
        currentURLs = [url]
        showPreviewPanel()
    }

    /// 预览多个文件
    func preview(urls: [URL]) {
        currentURLs = urls
        showPreviewPanel()
    }

    private func showPreviewPanel() {
        guard let panel = QLPreviewPanel.shared() else { return }

        panel.dataSource = self
        panel.delegate = self

        if !panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.reloadData()
        }

        previewPanel = panel
    }
}

// MARK: - QLPreviewPanelDataSource
extension QuickLookManager: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return currentURLs.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return currentURLs[index] as QLPreviewItem
    }
}

// MARK: - QLPreviewPanelDelegate
extension QuickLookManager: QLPreviewPanelDelegate {
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        return false
    }

    func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: QLPreviewItem!) -> NSRect {
        return .zero
    }
}
