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
        ZStack {
            // 背景色
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

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
        }
        .frame(width: 500, height: 400)
    }

    // 顶部标题栏
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "folder.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
            }

            Text("分组管理")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button(action: {
                WindowManager.shared.showWindow(
                    id: "addCategory",
                    title: "新建分组",
                    size: NSSize(width: 480, height: 520),
                    content: CategoryEditorView(category: nil)
                        .environment(\.managedObjectContext, viewContext)
                )
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("新建分组")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.accentColor)
                .cornerRadius(8)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // 分组列表
    private var categoryListView: some View {
        ScrollView {
            if categories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无分组")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("点击右上角按钮创建第一个分组")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(categories) { category in
                        CategoryRowView(
                            category: category,
                            onEdit: {
                                WindowManager.shared.showWindow(
                                    id: "editCategory_\(category.id?.uuidString ?? "")",
                                    title: "编辑分组",
                                    size: NSSize(width: 480, height: 520),
                                    content: CategoryEditorView(category: category)
                                        .environment(\.managedObjectContext, viewContext)
                                )
                            },
                            onDelete: { deleteCategory(category) }
                        )
                    }
                }
                .padding(20)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
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
}
