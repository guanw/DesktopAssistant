import SwiftUI
struct TranscribedText: View {
    @ObservedObject var recordingState : RecordingState
    @ObservedObject var chatState: ChatState
    var body: some View {
        ZStack {
            if recordingState.isRecording && chatState.transcribedText.isEmpty {
                ThreeDotsLoading() // Show loading animation
                    .frame(width: 100, height: 30)
            } else if (recordingState.isRecording) {
                Text("You said: " + chatState.transcribedText)
                    .font(.body)
                    .frame(width: 400, height: 50)
                    .cornerRadius(8)
                    .padding(8)
                    .shadow(radius: 3)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
