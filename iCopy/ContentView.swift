import SwiftUI

struct ContentView: View {
    @State private var selectedView: String? = "HistoryClipboard"

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // 左侧侧边栏
                VStack(spacing: 0) {
                    // Logo区域
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                        Text("iCopy")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // 菜单列表
                    List(selection: $selectedView) {
                        NavigationLink(
                            destination: HistoryClipboardView(),
                            tag: "HistoryClipboard",
                            selection: $selectedView
                        ) {
                            MenuButton(icon: "clipboard", title: "历史剪切板")
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))

                        NavigationLink(
                            destination: PromptManagementView(),
                            tag: "PromptManagement",
                            selection: $selectedView
                        ) {
                            MenuButton(icon: "text.bubble", title: "提示词管理")
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))

                        NavigationLink(
                            destination: SettingsView(),
                            tag: "Settings",
                            selection: $selectedView
                        ) {
                            MenuButton(icon: "gear", title: "通用设置")
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                    .listStyle(SidebarListStyle())

                    Spacer()
                }
                .frame(width: 180)
            }
            
            Divider()  // 添加分隔线
            
            // 右侧详细内容
            if selectedView == "HistoryClipboard" {
                HistoryClipboardView()
            } else if selectedView == "PromptManagement" {
                PromptManagementView()
            } else if selectedView == "Settings" {
                SettingsView()
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle()) // 使用双列导航视图样式
        .frame(width: 880, height: 692) // 固定窗口大小
    }
}

// 菜单按钮组件
struct MenuButton: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13))
        }
        .foregroundColor(.primary)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}