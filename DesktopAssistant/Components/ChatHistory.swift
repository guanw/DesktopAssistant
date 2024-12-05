import SwiftUI

struct ChatHistory: View {
    @ObservedObject var chatState : ChatState
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(chatState.messages, id: \.id) { chatMessage in
                            messageView(for: chatMessage)
                        }

                        chatState.waitingForReply ? ThreeDotsLoading()
                            .frame(width: 100, height: 30) : nil
                    }
                }
                .onChange(of: chatState.messages.count) { _ in
                    if let lastMessageId = chatState.messages.last?.id {
                        scrollView.scrollTo(lastMessageId)
                    }
                }
            }
        }
        .frame(width: Constants.CHAT_WIDTH, height: 400)
        .background(Color.black)
        .cornerRadius(12)
        .shadow(radius: 5)
    }

    private func messageView(for chatMessage: ChatMessage) -> AnyView {
        switch chatMessage {
        case .message(let message):
            return AnyView(ChatBubble(message: message).padding(5))
        case .multiModalMessage(let multiModalMessage):
            return AnyView(ChatBubble(message: Message(text: multiModalMessage.content.first?.text ?? "", role: .User)).padding(5))
        }
    }
}

