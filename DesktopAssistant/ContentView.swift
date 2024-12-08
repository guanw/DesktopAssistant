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

        if event.keyCode == 53 {
            Logger.shared.log("Esc key pressed")
            TextToSpeech.shared.stop()
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
    @StateObject private var recordingState = RecordingState()
    @StateObject private var chatState = ChatState()
    @StateObject private var imageState = ImageState()
    @State private var isAuthorized = false
    @State private var showFloatingWindow = false
    @State private var apiClient: GroqAPIClient = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let config = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil) as? [String: Any],
              let apiKey = config["GroqAPIKey"] as? String else {
            fatalError("Failed to load API key from Config.plist")
        }
        return GroqAPIClient(apiKey: apiKey, model: model)
    }()
    

    var body: some View {
        VStack() {
            KeyPressResponder {
                handleKeyPress()
            }
            .frame(width: 0, height: 0)

            ChatHistory(chatState: self.chatState)

            HStack () {
                ImageAttachment(imageState: self.imageState)

                ScreenshotButton(imageState: self.imageState)
            }


            TranscribedText(
                recordingState: recordingState,
                chatState: chatState
            )

            RecordingStateIndicator(recordingState: self.recordingState)

            if !isAuthorized {
                Text("Please enable speech recognition permission in System Settings")
                    .foregroundColor(.red)
            }

            InputBox(sendRequest: self.sendRequestToLargeLanguageModel)
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


    private func loadAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let config = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil) as? [String: Any],
              let apiKey = config["GroqAPIKey"] as? String else {
            Logger.shared.log("Failed to load API key from Config.plist")
            return nil
        }
        return apiKey
    }

    private func handleKeyPress() {
        // Start/Stop speech recording on Command+L press
        if !recordingState.isRecording {
            chatState.transcribedText = ""
            do {
                speechManager.onTranscription = { text in
                    chatState.transcribedText = text
                }
                try speechManager.startRecording()
            } catch {
                Logger.shared.log("Failed to start recording: \(error)")
            }
        } else {
            speechManager.stopRecording()
            self.sendRequestToLargeLanguageModel(transcribedText: chatState.transcribedText)
        }
        recordingState.isRecording.toggle()
    }

    private func sendRequestToLargeLanguageModel(transcribedText: String) {
        if (!transcribedText.isEmpty) {
            self.createInput(transcribedText: transcribedText)
            chatState.waitingForReply = true;
            apiClient.sendChatCompletionRequest(messages: chatState.messages) { result in
                switch result {
                case .success(let result):
                    self.parseSuccessReply(messages: chatState.messages, result: result, transcribedText: transcribedText)
                case .failure(let error):
                    chatState.messages.append(.message(Message(text: "Error: \(error.localizedDescription)", role: .System)))
                }

                // reset
                DispatchQueue.main.async {
                    chatState.waitingForReply = false;
                    chatState.transcribedText = ""
                }

                self.cleanupTempScreenshotFile()

            }

        }
    }

    private func cleanupTempScreenshotFile() {
        let fileManager = FileManager.default
        if (imageState.selectedFileUrl == nil) {
            return
        }
        do {
            defer {
                imageState.selectedFileUrl = nil
            }
            if fileManager.fileExists(atPath: imageState.selectedFileUrl!.path) {
                try fileManager.removeItem(at: imageState.selectedFileUrl!)
                Logger.shared.log("File deleted successfully.")
            } else {
                Logger.shared.log("File does not exist at \(imageState.selectedFileUrl!.path).")
            }
        } catch {
            Logger.shared.log("Failed to delete file: \(error.localizedDescription)")
        }

    }

    private func parseSuccessReply(messages: [ChatMessage], result: String, transcribedText: String) {
        if (CommandParser.isReminderCommand) {
            Logger.shared.log("reminder scheduled result: \(result)")
            let timeTuple = RemindMeUtils.parseTimeFromText(text: transcribedText)
            if (timeTuple == nil) {
                chatState.messages.append(.message(Message(text: "failed to extract hour and minute for reminder", role: .System)))
                Logger.shared.log("failed to extract hour and minute for reminder")
                return
            }
            RemindMeUtils.scheduleNotif(text: result, timeTuple: timeTuple!)
            chatState.messages.append(.message(Message(text: String(
                format: "reminder scheduled in %d hour(s) and %d minute(s)",
                timeTuple!.hours,
                timeTuple!.minutes
            ), role: .System)))
            return
        }
        DispatchQueue.main.async {
            chatState.messages.append(.message(Message(text: result, role: .System)))
        }
        TextToSpeech.shared.speak(result)
    }

    func createInput(transcribedText: String) {
        if model == STABLE_MODEL {
            chatState.messages.append(.message(Message(text: transcribedText, role: .User)))
        } else if model == MULTI_MODAL_MODEL {
            var content = [MultiModalMessageContent(text: transcribedText)]
            if let selectedFileUrl = imageState.selectedFileUrl {
                let imageUrl = ImageUtil.encodeImageToBase64(
                    imagePath: selectedFileUrl.path()
                )
                if let imageUrl = imageUrl {
                    content.append(
                        MultiModalMessageContent(
                            imageUrl: imageUrl
                        )
                    )
                }
            }
            chatState.messages.append(
                .multiModalMessage(
                    MultiModalMessage(role: .User, content: content)
                )
            )

        }
    }
}
