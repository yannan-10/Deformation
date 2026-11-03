import SwiftUI
import SwiftData

// MARK: - 收藏列表（仿备忘录）
struct FavoritesView: View {
    // @Query：自动从数据库读取所有收藏，按时间从新到旧排列
    @Query(sort: \SavedNote.createdAt, order: .reverse) private var notes: [SavedNote]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// 根据搜索框内容过滤
    private var filteredNotes: [SavedNote] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { $0.text.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    // 没有收藏时显示的提示
                    ContentUnavailableView(
                        "还没有收藏",
                        systemImage: "heart",
                        description: Text("在识别结果页面点「收藏」，文字会保存在这里")
                    )
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NavigationLink {
                                NoteDetailView(note: note)
                            } label: {
                                NoteRow(note: note)
                            }
                        }
                        .onDelete(perform: delete)   // 向左滑动删除
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("收藏")
            .searchable(text: $searchText, prompt: "搜索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                // 底部显示数量，和备忘录一样
                ToolbarItem(placement: .status) {
                    Text("\(notes.count) 条收藏")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredNotes[index])
        }
    }
}

// MARK: - 列表中的一行：标题 + 日期 + 预览
struct NoteRow: View {
    let note: SavedNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 8) {
                Text(note.createdAt.formatted(date: .numeric, time: .omitted))
                Text(note.preview)
                    .lineLimit(1)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 收藏详情：带注音显示，可以编辑
struct NoteDetailView: View {
    // @Bindable：可以直接修改 note，修改会自动保存
    @Bindable var note: SavedNote
    @State private var isEditing = false
    @State private var copied = false   // 是否刚刚复制过（用来切换图标）

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.createdAt.formatted(date: .long, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                if isEditing {
                    TextEditor(text: $note.text)
                        .font(.title3)
                        .frame(minHeight: 300)
                } else {
                    FuriganaText(segments: FuriganaGenerator.generate(note.text))
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 复制文字（可以粘贴到 AI 搜索里提问）
            ToolbarItem(placement: .primaryAction) {
                if !isEditing {
                    Button {
                        copyText()
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "完成" : "编辑") {
                    isEditing.toggle()
                }
            }
        }
    }

    /// 复制文字，图标会变成 ✓ 1.5 秒
    private func copyText() {
        UIPasteboard.general.string = note.text
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: SavedNote.self, inMemory: true)
}
