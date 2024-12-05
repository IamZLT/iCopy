import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            HStack(spacing: 0) {
                // 左侧侧边栏
                List {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 42))
                            .foregroundColor(.blue)
                        Text("iCopy")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.bottom, 20)
                    
                    NavigationLink(destination: Text("历史剪切板")) {
                        MenuButton(icon: "clipboard", title: "历史剪切板")
                    }
                    NavigationLink(destination: SettingsView()) {
                        MenuButton(icon: "gear", title: "通用设置")
                    }
                }
                .listStyle(SidebarListStyle())
               .frame(width: 150)  // 确保宽度固定
                
            }
            
            Divider()  // 添加分隔线
            
            // 右侧详细内容
            Text("请选择一个选项")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle()) // 使用双列导航视图样式
    }
}

// 菜单按钮组件
struct MenuButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 20)
            Text(title)
                .font(.system(size: 11))
        }
        .foregroundColor(.primary)
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}