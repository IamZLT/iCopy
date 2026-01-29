import SwiftUI
import ApplicationServices
import UserNotifications

struct SettingsView: View {
    // MARK: - AppStorage
    @AppStorage("openAppShortcut") private var openAppShortcut: String = "Cmd + Shift + O"
    @AppStorage("quickPasteShortcut") private var quickPasteShortcut: String = "Cmd + Shift + P"
    @AppStorage("showClipboardShortcut") private var showClipboardShortcut: String = "Cmd + Shift + C"
    @AppStorage("showPromptShortcut") private var showPromptShortcut: String = "Cmd + Shift + T"
    @AppStorage("maxHistoryCount") private var maxHistoryCount: String = "100"
    @AppStorage("autoCleanInterval") private var autoCleanInterval: Double = 0.0
    @AppStorage("pickerPosition") private var pickerPosition: String = "bottom"

    // MARK: - State
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @FocusState private var focusedField: FocusedField?
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasNotificationPermission: Bool = false
    @State private var showClipboardPicker: Bool = false
    @StateObject private var cleanupManager = ClipboardCleanupManager.shared

    enum FocusedField {
        case openAppShortcut, quickPasteShortcut, showClipboardShortcut, showPromptShortcut, maxHistoryCount
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            headerView
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, 24)

            // 内容区域
            ScrollView {
                VStack(spacing: 20) {
                    // 快捷键设置
                    shortcutSection

                    // 呼出位置设置
                    pickerPositionSection

                    // 剪切板设置
                    clipboardSection

                    // 权限设置
                    permissionSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .onChange(of: showClipboardPicker) { newValue in
            if newValue {
                showClipboardPickerWindow()
            }
        }
    }

    // MARK: - 顶部标题
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("通用设置")
                    .font(.system(size: 22, weight: .bold))
                Text("配置应用的各项功能")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - 快捷键设置
    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快捷键")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ShortcutEditRow(icon: "command", iconColor: .blue, title: "打开应用", shortcut: $openAppShortcut)
                Divider().padding(.leading, 40)
                ShortcutEditRow(icon: "doc.on.clipboard", iconColor: .green, title: "显示剪切板", shortcut: $showClipboardShortcut)
                Divider().padding(.leading, 40)
                ShortcutEditRow(icon: "text.bubble", iconColor: .orange, title: "显示提示词", shortcut: $showPromptShortcut)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - 呼出位置设置
    private var pickerPositionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("呼出位置")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack {
                Image(systemName: "location")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                    .frame(width: 24)

                Text("卡片显示位置")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Button(action: { showClipboardPicker = true }) {
                    Text("效果测试")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Picker("", selection: $pickerPosition) {
                    Text("屏幕顶部").tag("top")
                    Text("屏幕底部").tag("bottom")
                    Text("屏幕左侧").tag("left")
                    Text("屏幕右侧").tag("right")
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - 剪切板设置
    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("剪切板")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "number")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    Text("最大记录数")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()

                    TextField("", text: $maxHistoryCount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().padding(.leading, 40)

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        Text("自动清理")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(Int(autoCleanInterval)) 天")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 50)

                        Slider(value: $autoCleanInterval, in: 0...30, step: 1)
                            .frame(width: 120)
                            .onChange(of: autoCleanInterval) { _ in
                                cleanupManager.refreshCleanupSchedule()
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if autoCleanInterval > 0 {
                        HStack {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            Text("下次清理")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(cleanupManager.timeUntilNextCleanup)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.05))
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - 权限设置
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("权限")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "hand.raised")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 24)

                    Text("辅助功能权限")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()

                    if hasAccessibilityPermission {
                        Text("已授权")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("打开设置")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().padding(.leading, 40)

                HStack {
                    Image(systemName: "bell")
                        .font(.system(size: 14))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    Text("通知权限")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()

                    if hasNotificationPermission {
                        Text("已授权")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("打开设置")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .onAppear {
            checkPermissions()
        }
    }

    // MARK: - 权限检测
    private func checkPermissions() {
        // 检查辅助功能权限
        hasAccessibilityPermission = AXIsProcessTrusted()

        // 检查通知权限
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - 显示剪贴板选择器
    private func showClipboardPickerWindow() {
        showClipboardPicker = false // 重置状态

        // 使用 WindowManager 显示剪贴板选择器
        WindowManager.shared.showClipboardPicker(
            position: pickerPosition,
            context: PersistenceController.shared.container.viewContext
        )
    }
}

// MARK: - 快捷键编辑行组件
struct ShortcutEditRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var shortcut: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()

            ShortcutRecorderView(shortcut: $shortcut)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
