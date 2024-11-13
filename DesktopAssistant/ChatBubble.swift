import SwiftUI

struct ChatBubble: View {
    var message: Message
    
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
                Text(message.text)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(15)
                    .frame(maxWidth: 300, alignment: .leading)
                Spacer()
            }
        }
        .padding(message.role == .User ? .leading : .trailing, 50)
        .padding(.vertical, 5)
    }
}
