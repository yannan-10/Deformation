//
//  AISearchView.swift
//  Deformation
//
//  Created by BAIYANNAN on 2026/11/03.
//
import SwiftUI
import FoundationModels

/// 一条聊天消息
struct ChatMessage: Identifiable {
    enum Role {
        case user       // 用户的提问
        case assistant  // AI 的回答
    }

    let id = UUID()
    let role: Role
    let text: String
}

/// AI 搜索：使用苹果设备内置的 AI 模型（Foundation Models），免费、离线、不需要 API 密钥
struct AISearchView: View {
    /// 给 AI 的「角色设定」，每次对话都会遵守
    private static let instructions = """
    你是一名日语学习助手。用户是在日本学习日语的中国学生。
    用户会粘贴日语文章、句子或单词，并提出问题。
    请用简体中文回答，内容包括：读音（平假名）、意思、语法说明，必要时给出简单的例句。
    回答要简洁、易懂。
    """

    @Environment(\.dismiss) private var dismiss

    // 对话会话：会记住之前的内容，所以可以连续追问
    @State private var session = LanguageModelSession(instructions: AISearchView.instructions)
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isResponding = false

    private let model = SystemLanguageModel.default

    var body: some View {
        NavigationStack {
            Group {
                // 先检查这台设备能不能使用 AI
                switch model.availability {
                case .available:
                    chatView
                case .unavailable(let reason):
                    ContentUnavailableView(
                        "无法使用 AI 功能",
                        systemImage: "exclamationmark.triangle",
                        description: Text(unavailableMessage(for: reason))
                    )
                }
            }
            .navigationTitle("AI 搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    // 开始新对话（清空记录）
                    Button {
                        resetConversation()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(messages.isEmpty || isResponding)
                }
            }
        }
    }

    // MARK: - 聊天界面
    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            hintView
                        }
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isResponding {
                            ProgressView("思考中…")
                                .padding(.leading, 8)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                // 有新消息时自动滚到最下面
                .onChange(of: messages.count) {
                    if let lastID = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 底部输入框
            HStack(alignment: .bottom, spacing: 8) {
                TextField("粘贴日语文章或单词，输入问题…", text: $input, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(trimmedInput.isEmpty || isResponding)
            }
            .padding()
        }
    }

    /// 还没有对话时显示的使用说明
    private var hintView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("可以这样问：")
                .font(.headline)
            Text("・「納得」是什么意思？")
            Text("・解释这句话的语法：知らず知らずのうちに…")
            Text("・把这段文章翻译成中文：（粘贴文章）")
            Text("提示：在识别结果或收藏页面点复制按钮，再粘贴到下面的输入框。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .foregroundStyle(.primary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 发送问题
    private func send() async {
        let prompt = trimmedInput
        guard !prompt.isEmpty else { return }

        input = ""
        messages.append(ChatMessage(role: .user, text: prompt))
        isResponding = true

        do {
            // 把问题交给设备上的 AI 模型，等待回答
            let response = try await session.respond(to: prompt)
            messages.append(ChatMessage(role: .assistant, text: response.content))
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                text: "出错了：\(error.localizedDescription)\n如果对话太长，可以点右上角按钮开始新对话。"
            ))
        }

        isResponding = false
    }

    /// 清空对话，重新开始（AI 能记住的内容有限，对话太长时需要重新开始）
    private func resetConversation() {
        messages.removeAll()
        session = LanguageModelSession(instructions: AISearchView.instructions)
    }

    /// 根据不能使用的原因，显示对应的说明
    private func unavailableMessage(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "这台设备不支持 Apple Intelligence。"
        case .appleIntelligenceNotEnabled:
            return "请在「设置」中打开 Apple Intelligence。"
        case .modelNotReady:
            return "AI 模型正在下载或准备中，请稍后再试。"
        @unknown default:
            return "暂时无法使用 AI 功能。"
        }
    }
}

// MARK: - 聊天气泡
struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            Text(message.text)
                .textSelection(.enabled)   // 长按可以复制 AI 的回答
                .padding(12)
                .foregroundStyle(isUser ? .white : .primary)
                .background(isUser ? Color.pink : Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !isUser { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    AISearchView()
}
