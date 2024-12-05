import SwiftUI
struct InputBox: View {
    var sendRequest: (String) -> Void
    var body: some View {
        if Knobs.isTextInputEnabled {
            ChatInputView { newMessage in
                sendRequest(newMessage)
            }
        }
    }
}
