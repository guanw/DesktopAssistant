import SwiftUI

struct ChatBubble: View {
    var message: Message
    
    var body: some View {
        HStack {
            if message.isSender {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .frame(maxWidth: 300, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(15)
                    .frame(maxWidth: 300, alignment: .leading)
                Spacer()
            }
        }
        .padding(message.isSender ? .leading : .trailing, 50)
        .padding(.vertical, 5)
    }
}
