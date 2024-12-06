import SwiftUI
struct InputBox: View {
    @ObservedObject var knobs: Knobs = Knobs.shared
    var sendRequest: (String) -> Void
    var body: some View {
        if knobs.isTextInputEnabled {
            ChatInputView { newMessage in
                sendRequest(newMessage)
            }
        }
    }
}
