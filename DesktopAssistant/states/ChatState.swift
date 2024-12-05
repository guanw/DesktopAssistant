import Combine

class ChatState: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var waitingForReply: Bool = false
    @Published var transcribedText: String = ""
}
