import SwiftUI
import AppKit

struct ChatBubble: View {
    var message: any MessageProtocol
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            switch message.role {
            case .User:
                Spacer()
                userBubble
            case .System:
                Spacer()
                systemBubble
            case .Assistant:
                Spacer()
                systemBubble
            }
        }
        .padding(message.role == .User ? .leading : .trailing, 50)
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
        private var systemBubble: some View {
            HStack(spacing: 8) {
                if let textMessage = message as? Message {
                    Text(textMessage.text)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .frame(maxWidth: 300, alignment: .leading)
                } else if let multiModalMessage = message as? MultiModalMessage {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(multiModalMessage.content) { content in
                            switch content.type {
                            case .Text:
                                if let text = content.text {
                                    Text(text)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            case .Image_url:
                                if let imageUrl = content.imageUrl {
                                    Text("Image: \(imageUrl)")
                                        .padding(10)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    if let textMessage = message as? Message {
                        copyToClipboard(textMessage.text)
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(isPressed ? Color.blue : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .animation(.spring(), value: isPressed)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    self.isPressed.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isPressed = false
                    }
                }
            }
        }
    
    @ViewBuilder
        private var userBubble: some View {
            if let textMessage = message as? Message {
                Text(textMessage.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: .trailing)
            } else if let multiModalMessage = message as? MultiModalMessage {
                VStack(alignment: .trailing, spacing: 5) {
                    ForEach(multiModalMessage.content) { content in
                        switch content.type {
                        case .Text:
                            if let text = content.text {
                                Text(text)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        case .Image_url:
                            if let imageUrl = content.imageUrl {
                                Text("Image: \(imageUrl)") // Placeholder for image handling
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
        }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
