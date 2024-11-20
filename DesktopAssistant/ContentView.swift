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
let model = MULTI_MODAL_MODEL

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var messages: [ChatMessage] = []
    @State private var showFloatingWindow = false
    private let apiClient = GroqAPIClient(apiKey: "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", model: model)

    
    var body: some View {
        VStack() {
            KeyPressResponder {
                handleKeyPress()
            }
            .frame(width: 0, height: 0)
            
            chatHistory()
            
            translatedText()

            recordingStateIndicator()
            
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

    private func handleKeyPress() {
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
                self.createInput(transcribedText: transcribedText)
                apiClient.sendChatCompletionRequest(messages: messages) { result in
                    switch result {
                    case .success(let result):
                        messages.append(.message(Message(text: result, role: .System)))
                    case .failure(let error):
                        messages.append(.message(Message(text: "Error: \(error.localizedDescription)", role: .System)))
                    }
                }
                transcribedText = ""
            }
        }
        isRecording.toggle()
    }

    private func chatHistory() -> some View {
        return VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(messages, id: \.id) { chatMessage in
                            messageView(for: chatMessage)
                        }
                    }
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessageId = messages.last?.id {
                        scrollView.scrollTo(lastMessageId)
                    }
                }
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.black)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private func messageView(for chatMessage: ChatMessage) -> AnyView {
        switch chatMessage {
        case .message(let message):
            return AnyView(ChatBubble(message: message).padding(5))
        case .multiModalMessage(let multiModalMessage):
            return AnyView(ChatBubble(message: Message(text: multiModalMessage.content.first?.text ?? "", role: .User)).padding(5))
        }
    }

    private func translatedText() -> some View {
        return ZStack {
            if isRecording && transcribedText.isEmpty {
                ThreeDotsLoading() // Show loading animation
                    .frame(width: 100, height: 30)
            } else if (isRecording) {
                TextEditor(text: .constant(transcribedText))
                    .font(.body)
                    .frame(width: 400, height: 50)
                    .cornerRadius(8)
                    .padding(.vertical, 15)
                    .shadow(radius: 3)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func recordingStateIndicator() -> some View {
        return HStack(spacing: 20) {
            if isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
            } else {
                Text("Press CMD+l and start talking")
                    .foregroundColor(.gray)
            }
        }.padding()
    }
    
    func createInput(transcribedText: String) {
        if model == STABLE_MODEL {
            messages.append(.message(Message(text: transcribedText, role: .User)))
        } else if model == MULTI_MODAL_MODEL {
            messages.append(
                .multiModalMessage(
                    MultiModalMessage(role: .User, content: [MultiModalMessageContent(text: transcribedText)])
                )
            )
        }
    }
}
