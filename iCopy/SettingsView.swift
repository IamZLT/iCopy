import SwiftUI

struct SettingsView: View {
    @AppStorage("openAppShortcut") private var openAppShortcut: String = "Cmd + Shift + O"
    @AppStorage("quickPasteShortcut") private var quickPasteShortcut: String = "Cmd + Shift + P"
    @State private var maxHistoryCount: String = "100"
    @State private var autoCleanInterval: Double = 0.0 // in days
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @FocusState private var focusedField: FocusedField?

    enum FocusedField {
        case openAppShortcut, quickPasteShortcut
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "command")
                    .font(.title)
                    .foregroundColor(.purple)
                Text("快捷键设置")
                    .font(.title3)
                    .bold()
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 1)
                .overlay(
                    VStack(alignment: .leading, spacing: 15) {
                        ShortcutInputRow(
                            label: "打开应用:",
                            shortcut: $openAppShortcut,
                            focusedField: $focusedField,
                            currentField: .openAppShortcut,
                            onInvalidShortcut: handleInvalidShortcut
                        )
                        ShortcutInputRow(
                            label: "快速粘贴:",
                            shortcut: $quickPasteShortcut,
                            focusedField: $focusedField,
                            currentField: .quickPasteShortcut,
                            onInvalidShortcut: handleInvalidShortcut
                        )
                    }
                    .padding()
                )
                .frame(height: 100)

            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("剪切板历史记录管理")
                    .font(.title3)
                    .bold()
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 1)
                .overlay(
                    VStack(alignment: .leading, spacing: 15) {
                        ShortcutRow(label: "最大记录数:",
                                    shortcut: $maxHistoryCount,
                                    focusedField: $focusedField,
                                    currentField: nil,
                                    onInvalidShortcut: nil)
                        HStack {
                            Text("清理间隔 (天)")
                            Spacer()
                            Slider(value: $autoCleanInterval, in: 0...30, step: 1)
                                .frame(width: 90)
                            Text("\(Int(autoCleanInterval)) 天")
                                .frame(width: 50)
                        }
                    }
                    .padding()
                )
                .frame(height: 100)

            Spacer()
        }
        .padding(.horizontal)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("非法快捷键"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }

    private func handleInvalidShortcut(message: String) {
        alertMessage = message
        showAlert = true
    }
}

struct ShortcutRow: View {
    let label: String
    @Binding var shortcut: String
    @FocusState.Binding var focusedField: SettingsView.FocusedField?
    let currentField: SettingsView.FocusedField?
    let onInvalidShortcut: ((String) -> Void)?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $shortcut)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
                .multilineTextAlignment(.center) // 输入内容居中显示
                .focused($focusedField, equals: currentField)
                .onChange(of: focusedField) {
                    if focusedField == currentField {
                        // 当前焦点字段
                    } else {
                        // 焦点离开当前字段，执行其他逻辑（如验证）
                    }
                }
        }
    }

    private func validateShortcut(_ value: String, onInvalidShortcut: (String) -> Void) {
        if !isValidShortcut(value) {
            onInvalidShortcut("快捷键必须包含 Command 键的组合！")
            shortcut = "Cmd + " // 重置为默认值
        }
    }

    private func isValidShortcut(_ value: String) -> Bool {
        return value.lowercased().contains("cmd") && value.contains("+")
    }
}


struct ShortcutInputRow: View {
    let label: String
    @Binding var shortcut: String
    @FocusState.Binding var focusedField: SettingsView.FocusedField?
    let currentField: SettingsView.FocusedField?
    let onInvalidShortcut: ((String) -> Void)?
    
    @State private var capturedKeys: [String] = []

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $shortcut)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: currentField)
                .onTapGesture {
                    capturedKeys = []
                    focusedField = currentField
                }
                .keyboardShortcutEventHandler { event in
                    if focusedField == currentField {
                        handleKeyPress(event: event)
                    }
                }
        }
    }

    private func handleKeyPress(event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers else { return }

        var components: [String] = []

        if event.modifierFlags.contains(.command) { components.append("Cmd") }
        if event.modifierFlags.contains(.shift) { components.append("Shift") }
        if event.modifierFlags.contains(.option) { components.append("Option") }
        if event.modifierFlags.contains(.control) { components.append("Ctrl") }

        components.append(characters.uppercased())
        let newShortcut = components.joined(separator: " + ")

        if isValidShortcut(newShortcut) {
            shortcut = newShortcut
            DispatchQueue.main.async {
                focusedField = nil
            }
        } else {
            onInvalidShortcut?("快捷键必须包含 Command 键的组合！")
        }
    }
    private func isValidShortcut(_ value: String) -> Bool {
        return value.contains("Cmd") && value.contains("+")
    }
}

extension View {
    func keyboardShortcutEventHandler(handler: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventHandlerView(handler: handler))
    }
}

struct KeyEventHandlerView: NSViewRepresentable {
    let handler: (NSEvent) -> Void
    
    class Coordinator {
        var localEventMonitor: Any?
        
        deinit {
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event)
            return nil
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    SettingsView()
}
