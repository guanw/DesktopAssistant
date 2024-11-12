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
            print("Command + L pressed")
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

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var messages: [Message] = []
    @State private var showFloatingWindow = false

    
    var body: some View {
        VStack(spacing: 20) {
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
                        print("Failed to start recording: \(error)")
                    }
                } else {
                    speechManager.stopRecording()
                    if (!transcribedText.isEmpty) {
                        messages.append(Message(text: transcribedText, isSender: true))
                        messages.append(Message(text: transcribedText + " received", isSender: false))
                    }
                }
                isRecording.toggle()
            }
            .frame(width: 0, height: 0)

            Text("Voice Recognition")
                .font(.largeTitle)
                .padding()
            
            // chat history
            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                        }
                    }
                    .onChange(of: messages.count) {
                        scrollView.scrollTo(messages.last?.id)
                    }
                }
            }
            .frame(width: 400, height: 500)
            
            // current translated text
            TextEditor(text: .constant(transcribedText))
                .font(.body)
                .frame(height: 50)
                .padding()
                .border(Color.gray, width: 1)

            HStack(spacing: 20) {
                if isRecording {
                    Text("Recording...")
                        .foregroundColor(.red)
                } else {
                    Text("Stopped... press CMD+l and start talking")
                }
            }
            
            if !isAuthorized {
                Text("Please enable speech recognition permission in System Settings")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .frame(width: 500, height: 600)
        .padding()
        .onAppear {
            speechManager.requestAuthorization { authorized in
                isAuthorized = authorized
            }
        }
    }
}
