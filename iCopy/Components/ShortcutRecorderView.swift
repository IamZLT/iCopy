import SwiftUI
import AppKit

// 快捷键录制视图
struct ShortcutRecorderView: View {
    @Binding var shortcut: String
    @State private var isRecording = false
    @State private var recordedKeys: Set<UInt16> = []
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            // 快捷键显示/录制按钮
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                HStack(spacing: 6) {
                    if isRecording {
                        Text("按下快捷键...")
                            .foregroundColor(.orange)
                    } else {
                        Text(shortcut)
                            .foregroundColor(.primary)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minWidth: 120)
                .background(isRecording ? Color.orange.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // 清除按钮
            if !shortcut.isEmpty && !isRecording {
                Button(action: {
                    shortcut = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - 开始录制
    private func startRecording() {
        isRecording = true
        recordedKeys.removeAll()

        // 监听键盘事件
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            self.handleKeyEvent(event)
            return nil // 阻止事件传播
        }
    }

    // MARK: - 停止录制
    private func stopRecording() {
        isRecording = false

        // 移除事件监听
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - 处理键盘事件
    private func handleKeyEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            // 记录按键
            recordedKeys.insert(event.keyCode)

            // 构建快捷键字符串
            let modifiers = event.modifierFlags
            var components: [String] = []

            if modifiers.contains(.command) {
                components.append("Cmd")
            }
            if modifiers.contains(.shift) {
                components.append("Shift")
            }
            if modifiers.contains(.option) {
                components.append("Option")
            }
            if modifiers.contains(.control) {
                components.append("Ctrl")
            }

            // 添加按键字符
            if let keyChar = keyCodeToString(event.keyCode) {
                components.append(keyChar)
            }

            // 更新快捷键字符串
            if !components.isEmpty {
                shortcut = components.joined(separator: " + ")
                stopRecording()
            }
        }
    }

    // MARK: - 键码转字符串
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyCodeMap: [UInt16: String] = [
            0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
            0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
            0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
            0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
            0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
            0x06: "Z",
            0x1D: "0", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4",
            0x17: "5", 0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9",
            0x31: "Space", 0x24: "Return", 0x30: "Tab", 0x33: "Delete",
            0x35: "Escape"
        ]
        return keyCodeMap[keyCode]
    }
}
