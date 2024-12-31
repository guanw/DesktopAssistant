import Combine

class RecordingState: ObservableObject {
    static let shared = RecordingState()
    @Published var isRecording: Bool = false
}
