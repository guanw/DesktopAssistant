import SwiftUI
import Speech

struct KeyPressResponder: NSViewRepresentable {
    var onKeyPress: (() -> Void)?

    func makeNSView(context: Context) -> KeyPressResponderView {
        return KeyPressResponderView(onKeyPress: onKeyPress)
    }

    func updateNSView(_ nsView: KeyPressResponderView, context: Context) {}
}

// Custom NSView to handle keypress events
class KeyPressResponderView: NSView {
    var onKeyPress: (() -> Void)?

    init(onKeyPress: (() -> Void)?) {
        self.onKeyPress = onKeyPress
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        // Detect Command + L keypress
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "l" {
            Logger.shared.log("Command + L pressed")
            onKeyPress?()  // Trigger the passed callback
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
}

let MULTI_MODAL_MODEL = "llama-3.2-90b-vision-preview"
let STABLE_MODEL = "llama3-8b-8192"

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var messages: [Message] = []
    @State private var showFloatingWindow = false
    private let apiClient = GroqAPIClient(apiKey: "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", model: STABLE_MODEL)

    
    var body: some View {
        VStack() {
            KeyPressResponder {
                // Start/Stop speech recording on Command+L press
                if !isRecording {
                    transcribedText = ""
                    do {
                        speechManager.onTranscription = { text in
                            transcribedText = text
                        }
                        try speechManager.startRecording()
                    } catch {
                        Logger.shared.log("Failed to start recording: \(error)")
                    }
                } else {
                    speechManager.stopRecording()
                    if (!transcribedText.isEmpty) {
                        messages.append(Message(text: transcribedText, role: .User))
                        apiClient.sendChatCompletionRequest(messages: messages) { result in
                            switch result {
                            case .success(let result):
                                messages.append(Message(text: result, role: .System))
                            case .failure(let error):
                                messages.append(Message(text: "Error: \(error.localizedDescription)", role: .System))
                            }
                        }
                        transcribedText = ""
                    }
                }
                isRecording.toggle()
            }
            .frame(width: 0, height: 0)
            
            // chat history
            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .padding(5)
                            }
                        }
                    }
                    .onChange(of: messages.count) {
                        scrollView.scrollTo(messages.last?.id)
                    }
                }
            }
            .frame(width: 400, height: 400)
            .background(Color.black)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            // current translated text
            ZStack {
                if isRecording && transcribedText.isEmpty {
                    ThreeDotsLoading() // Show loading animation
                        .frame(width: 100, height: 30)
                } else if (isRecording) {
                    TextEditor(text: .constant(transcribedText))
                        .font(.body)
                        .frame(width: 400, height: 50)
                        .cornerRadius(8)
                        .padding()
                        .shadow(radius: 3)
                }
            }

            HStack(spacing: 20) {
                if isRecording {
                    Text("Recording...")
                        .foregroundColor(.red)
                } else {
                    Text("Press CMD+l and start talking")
                        .foregroundColor(.gray)
                }
            }.padding()
            
            if !isAuthorized {
                Text("Please enable speech recognition permission in System Settings")
                    .foregroundColor(.red)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onAppear {
            speechManager.requestAuthorization { authorized in
                isAuthorized = authorized
            }
        }
    }
}
