import Foundation
import AppKit
import Carbon
import CoreData

// 快捷键管理器
class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventHandlers: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotkeys: [EventHotKeyRef?] = []

    private init() {
        setupEventHandler()
    }

    deinit {
        unregisterAllHotkeys()
        if let handlerRef = eventHandlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    // 设置事件处理器
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let error = GetEventParameter(
                theEvent,
                UInt32(kEventParamDirectObject),
                UInt32(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if error == noErr {
                let manager = HotkeyManager.shared
                manager.eventHandlers[hotKeyID.id]?()
            }

            return noErr
        }, 1, &eventType, nil, &eventHandlerRef)
    }

    // 注册快捷键
    func registerHotkey(id: UInt32, keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B455920), id: id) // 'KEY '
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            eventHandlers[id] = handler
            registeredHotkeys.append(hotKeyRef)
            print("✅ 成功注册快捷键 ID: \(id)")
        } else {
            print("❌ 注册快捷键失败 ID: \(id), 状态码: \(status)")
        }
    }

    // 注销所有快捷键
    func unregisterAllHotkeys() {
        for hotKeyRef in registeredHotkeys {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        registeredHotkeys.removeAll()
        eventHandlers.removeAll()
        print("🗑️ 已注销所有快捷键")
    }

    // 解析快捷键字符串（例如 "Cmd + Shift + C"）
    func parseShortcut(_ shortcut: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        let components = shortcut.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }

        var modifiers: UInt32 = 0
        var keyChar: String?

        for component in components {
            switch component.lowercased() {
            case "cmd", "command", "⌘":
                modifiers |= UInt32(cmdKey)
            case "shift", "⇧":
                modifiers |= UInt32(shiftKey)
            case "option", "alt", "⌥":
                modifiers |= UInt32(optionKey)
            case "control", "ctrl", "⌃":
                modifiers |= UInt32(controlKey)
            default:
                keyChar = component.uppercased()
            }
        }

        guard let key = keyChar, let keyCode = keyCodeMap[key] else {
            return nil
        }

        return (keyCode, modifiers)
    }

    // 键码映射表
    private let keyCodeMap: [String: UInt32] = [
        "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02, "E": 0x0E,
        "F": 0x03, "G": 0x05, "H": 0x04, "I": 0x22, "J": 0x26,
        "K": 0x28, "L": 0x25, "M": 0x2E, "N": 0x2D, "O": 0x1F,
        "P": 0x23, "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
        "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07, "Y": 0x10,
        "Z": 0x06,
        "0": 0x1D, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15,
        "5": 0x17, "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19,
        "SPACE": 0x31, "RETURN": 0x24, "TAB": 0x30, "DELETE": 0x33,
        "ESCAPE": 0x35, "ESC": 0x35
    ]
}
