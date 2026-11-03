import SwiftUI
import SwiftData

/// 显示图片和带注音的识别结果，可以修改文字、收藏
struct ResultView: View {
    let image: UIImage

    @State private var text = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditing = false        // 是否处于编辑文字模式
    @State private var savedNote: SavedNote?    // 收藏后的记录（nil = 还没收藏）
    @State private var copied = false           // 是否刚刚复制过（用来切换图标）

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 识别成功并且有文字时，才能收藏
    private var canSave: Bool {
        !isLoading && errorMessage == nil && !text.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 原图（限制高度，把空间留给文字）
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if isLoading {
                        ProgressView("正在识别文字…")
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else if isEditing {
                        Text("修改识别错误的文字，完成后点右上角「完成」")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $text)
                            .font(.title3)
                            .frame(minHeight: 300)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3))
                            )
                    } else if text.isEmpty {
                        Text("没有识别到文字")
                            .foregroundStyle(.secondary)
                    } else {
                        FuriganaText(segments: FuriganaGenerator.generate(text))
                    }
                }
                .padding()
            }
            // 收藏按钮固定在屏幕底部，文章很长时也不用滚到最下面
            .safeAreaInset(edge: .bottom) {
                if canSave && !isEditing {
                    Button {
                        saveNote()
                    } label: {
                        Label(savedNote == nil ? "收藏" : "已收藏",
                              systemImage: savedNote == nil ? "heart" : "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .controlSize(.large)
                    .disabled(savedNote != nil)
                    .padding()
                }
            }
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                // 复制文字（可以粘贴到 AI 搜索里提问）
                ToolbarItem(placement: .primaryAction) {
                    if canSave && !isEditing {
                        Button {
                            copyText()
                        } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !isLoading && errorMessage == nil {
                        Button(isEditing ? "完成" : "编辑") {
                            if isEditing {
                                // 已经收藏过的话，把修改后的文字同步到收藏里
                                savedNote?.text = text
                            }
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
        // 页面出现时自动开始识别
        .task {
            await recognize()
        }
    }

    private func recognize() async {
        do {
            text = try await TextRecognizer.recognize(image)
        } catch {
            errorMessage = "识别失败：\(error.localizedDescription)"
        }
        isLoading = false
    }

    /// 复制识别出的文字，图标会变成 ✓ 1.5 秒
    private func copyText() {
        UIPasteboard.general.string = text
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }

    /// 保存文字到收藏（只存文字，不存照片）
    private func saveNote() {
        let note = SavedNote(text: text)
        modelContext.insert(note)
        savedNote = note
    }
}
