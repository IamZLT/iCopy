import SwiftUI

struct SettingsView: View {
    @AppStorage("openAppShortcut") private var openAppShortcut: String = "Cmd + Shift + O" 
    // 打开应用的快捷键

    @AppStorage("quickPasteShortcut") private var quickPasteShortcut: String = "Cmd + Shift + P" 
    // 快速粘贴的快捷键

    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100" 
    // 最大历史记录数

    @AppStorage("autoCleanInterval") private var autoCleanInterval: Double = 0.0 
    // 自动清理间隔（天）

    @State private var showAlert: Bool = false 
    // 是否显示警告

    @State private var alertMessage: String = "" 
    // 警告信息

    @FocusState private var focusedField: FocusedField? 
    // 当前聚焦的字段

    enum FocusedField {
        case openAppShortcut, quickPasteShortcut, maxHistoryCount 
        // 聚焦字段的枚举，表示当前输入的快捷键字段
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "command") 
                // 显示命令图标

                .font(.title)
                .foregroundColor(.purple)

                Text("快捷键设置") 
                // 快捷键设置标题

                .font(.title3)
                .bold()
            }

            RoundedRectangle(cornerRadius: 10) 
            // 设置背景为圆角矩形

                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 1)
                .overlay(
                    VStack(alignment: .leading, spacing: 15) {
                        ShortcutInputRow( 
                        // 打开应用的快捷键输入行

                            label: "打开应用:",
                            shortcut: $openAppShortcut,
                            focusedField: $focusedField,
                            currentField: .openAppShortcut,
                            onInvalidShortcut: handleInvalidShortcut
                        )
                        ShortcutInputRow( 
                        // 快速粘贴的快捷键输入行

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
                // 显示剪切板图标

                    .font(.title)
                    .foregroundColor(.blue)

                Text("剪切板历史记录管理") 
                // 剪切板历史记录管理标题

                    .font(.title3)
                    .bold()
            }

            RoundedRectangle(cornerRadius: 10) 
            // 设置背景为圆角矩形

                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 1)
                .overlay(
                    VStack(alignment: .leading, spacing: 15) {
                        ShortcutRow(
                            label: "最大记录数:",
                            shortcut: $maxHistoryCount,
                            focusedField: $focusedField,
                            currentField: .maxHistoryCount,
                            onInvalidShortcut: nil
                        )
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
            // 显示警告框
            Alert(title: Text("非法快捷键"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }

    private func handleInvalidShortcut(message: String) {
        // 处理无效快捷键的逻辑
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
    
    @State private var isEditing: Bool = false // Track editing state

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ZStack(alignment: .trailing) {
                TextField("", text: $shortcut)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: currentField)
                    .onTapGesture {
                        isEditing = true
                        focusedField = currentField // 确保设置焦点
                    }
                    .onSubmit {
                        isEditing = false
                        // 在这里更新 maxHistoryCount 的值
                        if let newValue = Int(shortcut) {
                            // 假设 maxHistoryCount 是一个 Int 类型的变量
                            // maxHistoryCount = newValue
                        } else {
                            // 如果输入无效，可以显示警告或重置为默认值
                            onInvalidShortcut?("请输入有效的数字！")
                        }
                        // 延迟清除焦点以避免文本被选中
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            focusedField = nil
                        }
                    }
                    .onChange(of: focusedField) { newValue in
                        isEditing = (newValue == currentField)
                    }
                
                // Display return icon only when editing
                if isEditing {
                    Image(systemName: "return")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                        .padding(.trailing, 8)
                }
            }
        }
    }

    private func validateShortcut(_ value: String, onInvalidShortcut: (String) -> Void) {
        // 验证快捷键的有效性
        if !isValidShortcut(value) {
            onInvalidShortcut("快捷键必须包含 Command 键的组合！")
            shortcut = "Cmd + " // 重置为默认值
        }
    }

    private func isValidShortcut(_ value: String) -> Bool {
        // 检查快捷键是否有效
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
    // 捕获按键数组

    var body: some View {
        HStack {
            Text(label) 
            // 显示标签

            Spacer()
            ZStack(alignment: .trailing) {
                TextField("", text: $shortcut)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: currentField)
                    .onTapGesture {
                        capturedKeys = []
                        focusedField = currentField
                    }
                    .keyboardShortcutEventHandler(onKeyDown: handleKeyPress)
                
                // 加回车图标
                if focusedField == currentField {
                    Image(systemName: "return")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                        .padding(.trailing, 8)
                }
            }
        }
    }

    private func handleKeyPress(event: NSEvent) {
        // 处理按键事件
        guard let characters = event.charactersIgnoringModifiers else { return }

        var components: [String] = []

        if event.modifierFlags.contains(.command) { components.append("Cmd") }
        if event.modifierFlags.contains(.shift) { components.append("Shift") }
        if event.modifierFlags.contains(.option) { components.append("Option") }
        if event.modifierFlags.contains(.control) { components.append("Ctrl") }

        components.append(characters.uppercased())
        let newShortcut = components.joined(separator: " + ")

        if isValidShortcut(newShortcut) {
            // 如果快捷键有效，更新快捷键并清除焦点
            shortcut = newShortcut
            DispatchQueue.main.async {
                focusedField = nil
            }
        } else {
            // 如果快捷键无效，调用无效快捷键处理函数
            onInvalidShortcut?("快捷键必须包含 Command 的组合！")
        }
    }
    
    private func isValidShortcut(_ value: String) -> Bool {
        // 检查快捷键是否有效
        return value.contains("Cmd") && value.contains("+")
    }
}

extension View {
    func keyboardShortcutEventHandler(onKeyDown handler: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventHandlerView(onKeyDown: handler))
    }
}

#Preview {
    SettingsView() 
    // 预览设置视图
}