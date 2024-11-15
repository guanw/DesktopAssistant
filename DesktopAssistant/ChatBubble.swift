import SwiftUI
import AppKit

struct ChatBubble: View {
    var message: Message
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            switch message.role {
            case .User:
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .frame(maxWidth: 300, alignment: .trailing)
            case .System:
                Spacer()
                HStack(spacing: 8) {
                    Text(message.text)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(15)
                        .frame(maxWidth: 300, alignment: .leading)
                    Button(action: {
                        copyToClipboard(message.text)
                    }) {
                        Image(systemName: "doc.on.doc") // Copy icon
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(isPressed ? Color.blue : Color.gray.opacity(0.1)) // Change background when pressed
                            .clipShape(Circle())
                            .scaleEffect(isPressed ? 1.1 : 1.0) // Scale the button when pressed
                            .animation(.spring(), value: isPressed) // Add spring animation for scaling
                    }
                    .buttonStyle(PlainButtonStyle()) // Plain button style for macOS to prevent default effects
                    .onTapGesture {
                        // Change state on tap, to trigger visual feedback
                        self.isPressed.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isPressed = false
                        }
                    }
                }
            }
        }
        .padding(message.role == .User ? .leading : .trailing, 50)
        .padding(.vertical, 5)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
