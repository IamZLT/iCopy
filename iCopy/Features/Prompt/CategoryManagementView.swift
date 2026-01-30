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
            headerView
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            // 分组列表
            categoryListView

            // 底部按钮
            footerView
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 500, height: 400)
    }

    // 顶部标题栏
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "folder.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("分组管理")
                    .font(.system(size: 20, weight: .bold))
                Text("\(categories.count) 个分组")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

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
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // 分组列表
    private var categoryListView: some View {
        ScrollView {
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
}
