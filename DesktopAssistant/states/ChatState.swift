import Combine

class ChatState: ObservableObject {
    static let shared = ChatState()
    @Published var messages: [ChatMessage] = []
    @Published var waitingForReply: Bool = false
    @Published var transcribedText: String = ""
}
