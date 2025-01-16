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
                UserBubble
            case .System:
                Spacer()
                SystemBubble
            case .Assistant:
                Spacer()
                SystemBubble
            }
        }
    }
    
    @ViewBuilder
    private var SystemBubble: some View {
        HStack(alignment: .center, spacing: 4) {
            // Text or multi-modal message content
            if let textMessage = message as? Message {
                Text(textMessage.text)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .frame(alignment: .leading) // Ensure text bubble spans width and aligns left
                    .textSelection(.enabled)
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
                                    .textSelection(.enabled)
                            }
                        case .Image_url:
                            if let imageUrl = content.imageUrl {
                                Text("Image: \(imageUrl)")
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .frame(alignment: .leading) // Align content to the left
            }

            // Copy button aligned to the right of the HStack
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
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure the HStack respects the container size
    }

    @ViewBuilder
    private var UserBubble: some View {
        HStack(spacing: 8) {
            if let textMessage = message as? Message {
                Text(textMessage.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .textSelection(.enabled)
            } else if let multiModalMessage = message as? MultiModalMessage {
                VStack(spacing: 5) {
                    ForEach(multiModalMessage.content) { content in
                        switch content.type {
                        case .Text:
                            if let text = content.text {
                                Text(text)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .textSelection(.enabled)
                            }
                        case .Image_url:
                            if let imageUrl = content.imageUrl {
                                Text("Image: \(imageUrl)") // Placeholder for image handling
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .textSelection(.enabled)
                            }
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
