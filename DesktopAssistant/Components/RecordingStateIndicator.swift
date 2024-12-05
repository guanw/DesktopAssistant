import SwiftUI

struct RecordingStateIndicator: View {
    @StateObject private var recordingState = RecordingState()
    var body: some View {
        HStack(spacing: 20) {
            if recordingState.isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
            } else {
                Text("Press CMD+l and start talking, press again to stop")
                    .foregroundColor(.gray)
            }
        }.padding()
    }
}
