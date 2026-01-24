import SwiftUI
import CoreData

// 剪贴板选择弹窗
struct ClipboardPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default)
    private var clipboardItems: FetchedResults<ClipboardItem>

    @State private var searchText = ""
    @Binding var isPresented: Bool
    let onSelect: (ClipboardItem) -> Void

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(clipboardItems)
        } else {
            return clipboardItems.filter { item in
                item.content?.localizedCaseInsensitiveContains(searchText) == true ||
                item.title?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Image(systemName: "clipboard")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("选择剪贴板历史")
                    .font(.title3)
                    .bold()
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索剪贴板内容...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            Divider()

            // 剪贴板列表
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                clipboardListView
            }
        }
        .frame(width: 800, height: 600)
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无剪贴板历史")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 剪贴板列表视图
    private var clipboardListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredItems) { item in
                    ClipboardPickerCardView(item: item) {
                        onSelect(item)
                        isPresented = false
                    }
                }
            }
            .padding()
        }
    }
}
