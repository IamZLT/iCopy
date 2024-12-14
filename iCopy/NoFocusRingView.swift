import SwiftUI
import AppKit

struct NoFocusRingView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.focusRingType = .none
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}