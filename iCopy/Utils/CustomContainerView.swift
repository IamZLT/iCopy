import SwiftUI
import AppKit

struct CustomContainerView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void
    
    class CustomView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        
        init(onKeyDown: @escaping (NSEvent) -> Void) {
            self.onKeyDown = onKeyDown
            super.init(frame: .zero)
            
            self.focusRingType = .none
            self.wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = CustomView(onKeyDown: onKeyDown)
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let window = view.window {
                window.makeFirstResponder(view)
                window.makeKey()
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
} 