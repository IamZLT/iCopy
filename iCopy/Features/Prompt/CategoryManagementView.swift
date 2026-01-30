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

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }

                Text("分组管理")
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                Button(action: {
                    WindowManager.shared.showWindow(
                        id: "addCategory",
                        title: "新建分组",
                        size: NSSize(width: 480, height: 380),
                        content: CategoryEditorView(category: nil)
                            .environment(\.managedObjectContext, viewContext)
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("新建分组")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(7)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            // 分组列表
            categoryListView
                .background(Color(NSColor.windowBackgroundColor))

            // 底部按钮
            footerView
                .background(Color(NSColor.windowBackgroundColor))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 500, height: 400)
    }

    // 分组列表
    private var categoryListView: some View {
        Group {
            if categories.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.orange.opacity(0.6))
                    }

                    VStack(spacing: 8) {
                        Text("暂无分组")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("点击右上角按钮创建第一个分组")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(categories) { category in
                        CategoryRowView(
                            category: category,
                            onEdit: {
                                WindowManager.shared.showWindow(
                                    id: "editCategory_\(category.id?.uuidString ?? "")",
                                    title: "编辑分组",
                                    size: NSSize(width: 480, height: 380),
                                    content: CategoryEditorView(category: category)
                                        .environment(\.managedObjectContext, viewContext)
                                )
                            },
                            onDelete: { deleteCategory(category) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveCategory)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // 底部按钮
    private var footerView: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Text("完成")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 100)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // 删除分组
    private func deleteCategory(_ category: PromptCategory) {
        withAnimation {
            viewContext.delete(category)
            try? viewContext.save()
        }
    }

    // 移动分组（拖动排序）
    private func moveCategory(from source: IndexSet, to destination: Int) {
        var categoriesArray = Array(categories)
        categoriesArray.move(fromOffsets: source, toOffset: destination)

        // 更新所有分组的 sortOrder
        for (index, category) in categoriesArray.enumerated() {
            category.sortOrder = Int16(index)
        }

        // 保存更改
        try? viewContext.save()
    }
}
