import SwiftUI
import CoreData

/// 分组管理视图
struct CategoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PromptCategory.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<PromptCategory>

    @State private var showingAddCategory = false
    @State private var editingCategory: PromptCategory?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            headerView

            Divider()

            // 分组列表
            categoryListView

            Divider()

            // 底部按钮
            footerView
        }
        .frame(width: 500, height: 400)
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorView(category: nil)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // 顶部标题栏
    private var headerView: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text("分组管理")
                .font(.title3)
                .bold()
            Spacer()
            Button(action: { showingAddCategory = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加分组")
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // 分组列表
    private var categoryListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(categories) { category in
                    CategoryRowView(
                        category: category,
                        onEdit: { editingCategory = category },
                        onDelete: { deleteCategory(category) }
                    )
                }
            }
            .padding()
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Spacer()
            Button("关闭") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // 删除分组
    private func deleteCategory(_ category: PromptCategory) {
        withAnimation {
            viewContext.delete(category)
            try? viewContext.save()
        }
    }
}
