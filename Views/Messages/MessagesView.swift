import SwiftUI

struct MessagesView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        _MessagesViewContent(
            viewModel: viewModel,
            messageText: $messageText,
            isInputActive: $isInputActive
        )
    }
}

private struct _MessagesViewContent: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var messageText: String
    var isInputActive: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 0) {
            _MessagesList(messages: viewModel.messages, currentUsername: viewModel.currentUser.username)
            Divider()
            _MessageInputView(
                messageText: $messageText,
                isInputActive: isInputActive,
                onSendMessage: { content in
                    sendMessage(content: content)
                }
            )
        }
        .navigationTitle("Mesajlar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isInputActive.wrappedValue = true
        }
    }
    
    private func sendMessage(content: String) {
        let currentUser = viewModel.currentUser.id
        let partner = viewModel.partner.id
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await viewModel.sendMessage(content: trimmed)
        }
        messageText = ""
    }
}

private struct _MessageInputView: View {
    @Binding var messageText: String
    var isInputActive: FocusState<Bool>.Binding
    let onSendMessage: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Mesajınızı yazın...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused(isInputActive)
                .onSubmit {
                    onSendMessage(messageText)
                }
            Button(action: { onSendMessage(messageText) }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    .font(.system(size: 22))
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
    }
}

private struct _MessagesList: View {
    let messages: [Message]
    let currentUsername: String?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        _MessageRowView(message: message, currentUsername: currentUsername)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation {
                        scrollProxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let last = messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollProxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct _MessageRowView: View {
    let message: Message
    let currentUsername: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.senderId == currentUsername {
                Spacer()
                ConversationMessageBubble(message: message, isCurrentUser: true)
            } else {
                ConversationMessageBubble(message: message, isCurrentUser: false)
                Spacer()
            }
        }
    }
}

struct ConversationMessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
            Text(message.content)
                .padding(10)
                .background(isCurrentUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(14)
            Text(message.createdAt, style: .time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: 260, alignment: isCurrentUser ? .trailing : .leading)
        .padding(isCurrentUser ? .leading : .trailing, 40)
    }
} 