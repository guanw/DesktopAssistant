import Foundation

enum ChatMessage: Identifiable {
    case message(Message)
    case multiModalMessage(MultiModalMessage)

    var id: UUID {
        switch self {
        case .message(let message):
            return message.id
        case .multiModalMessage(let multiModalMessage):
            return multiModalMessage.id
        }
    }
}

protocol MessageProtocol: Identifiable {
    var id: UUID { get }
    var role: Role { get }
}

enum Role: String {
    case User = "user"
    case System = "system"
    case Assistant = "assistant"
}

struct Message: Identifiable, MessageProtocol {
    let id = UUID()
    let text: String
    let role: Role
}

struct MultiModalMessage: Identifiable, MessageProtocol {
    let id = UUID()
    let role: Role
    let content: [MultiModalMessageContent]
}

struct MultiModalMessageContent: Identifiable {
    let id = UUID()
    let type: MultiModalMessageType
    let text: String?
    let imageUrl: String?
    
    init(text: String) {
        self.type = MultiModalMessageType.Text
        self.text = text
        self.imageUrl = nil
    }
    
    init(imageUrl: String) {
        self.type = MultiModalMessageType.Image_url
        self.text = nil
        self.imageUrl = imageUrl
    }
}

enum MultiModalMessageType: String {
    case Text = "text"
    case Image_url = "image_url"
}
