import SwiftUI

struct ChatInputView: View {
    @State private var userInput: String = "" // State variable to hold user input
    var onSend: (String) -> Void // Callback to handle sending the message

    var body: some View {
        HStack {
            TextField("Type your message...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle()) // Style for the text field
                .padding(.leading, 8)
                .disableAutocorrection(true) // Disable autocorrection if not needed
                .onSubmit { // Triggered when the user presses "Return"
                    sendMessage()
                }

            Button(action: {
                sendMessage()
            }) {
                Image(systemName: "paperplane.fill") // Icon for the send button
                    .foregroundColor(userInput.isEmpty ? .gray : .blue) // Disabled state
            }
            .disabled(userInput.isEmpty) // Disable button when input is empty
            .padding(.trailing, 8)
        }
        .padding()
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Optional shadow for better UI
    }

    // Helper function to handle sending the message
    private func sendMessage() {
        if !userInput.isEmpty {
            onSend(userInput)
            userInput = "" // Clear the input after sending
        }
    }
}
