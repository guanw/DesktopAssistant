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
    @State private var transcribedText = ""
    @StateObject private var recordingState = RecordingState()
    @StateObject private var chatState = ChatState()
    @State private var isAuthorized = false
    @State private var showFloatingWindow = false
    @State private var selectedFileUrl: URL? = nil
    @State private var isAttachPageClickableHovered = false
    @State private var isScreenshotClickableHovered = false
    @State private var apiClient: GroqAPIClient = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let config = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil) as? [String: Any],
              let apiKey = config["GroqAPIKey"] as? String else {
            fatalError("Failed to load API key from Config.plist")
        }
        return GroqAPIClient(apiKey: apiKey, model: model)
    }()
//    @State private var llamaClient: LlamaClient;
    @State private var llamaResponse = ""

    var body: some View {
        VStack() {
            KeyPressResponder {
                handleKeyPress()
            }
            .frame(width: 0, height: 0)

            ChatHistory(chatState: self.chatState)

            HStack () {
                imageAttachment()

                screenshotButton()
            }


            translatedText()

            RecordingStateIndicator(recordingState: self.recordingState)

            llamaButtonPlayground()

            if !isAuthorized {
                Text("Please enable speech recognition permission in System Settings")
                    .foregroundColor(.red)
            }

            InputBox()
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
            self.sendRequestToLargeLanguageModel(transcribedText: transcribedText)
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
                }
                self.transcribedText = ""
                self.cleanupTempScreenshotFile()

            }

        }
    }

    private func cleanupTempScreenshotFile() {
        let fileManager = FileManager.default
        if (self.selectedFileUrl == nil) {
            return
        }
        do {
            defer {
                self.selectedFileUrl = nil
            }
            if fileManager.fileExists(atPath: self.selectedFileUrl!.path) {
                try fileManager.removeItem(at: self.selectedFileUrl!)
                Logger.shared.log("File deleted successfully.")
            } else {
                Logger.shared.log("File does not exist at \(self.selectedFileUrl!.path).")
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

    private func imageAttachment() -> some View {
        let content =
        {
            if let text = self.selectedFileUrl?.lastPathComponent {
                return "Attach Image: " + text
            } else {
                return "Attach Image"
            }
        }()
        return Button(action: {
            openImagePicker()
        }) {
            HStack {
                Image(systemName: "paperclip.circle")
                    .resizable()
                    .frame(width: 24, height: 24)

                Text(
                    content
                )
            }
            .foregroundColor(isAttachPageClickableHovered ? .blue : .primary) // Change color on hover
            .onHover { hovering in
                isAttachPageClickableHovered = hovering
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private func screenshotButton() -> some View {
        return Button(action: {
            TakeScreensShots(fileNamePrefix: "screenshot")
        }) {
            HStack {
                Image(systemName: "scroll")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .help("Take screenshot and attach")
                    .foregroundColor(isScreenshotClickableHovered ? .blue : .primary) // Change color on hover
                    .onHover { hovering in
                        isScreenshotClickableHovered = hovering
                    }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private func openImagePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.jpeg] // Allow image file types
        openPanel.allowsMultipleSelection = false // Single file selection
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select an Image (jpeg)"

        if openPanel.runModal() == .OK, let selectedFileURL = openPanel.url {
            if let _ = NSImage(contentsOf: selectedFileURL) {
                self.selectedFileUrl = selectedFileURL
            } else {
                Logger.shared.log("Failed to load image")
            }
        }
    }

    private func translatedText() -> some View {
        return ZStack {
            if recordingState.isRecording && transcribedText.isEmpty {
                ThreeDotsLoading() // Show loading animation
                    .frame(width: 100, height: 30)
            } else if (recordingState.isRecording) {
                Text("You said: " + transcribedText)
                    .font(.body)
                    .frame(width: 400, height: 50)
                    .cornerRadius(8)
                    .padding(8)
                    .shadow(radius: 3)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func TakeScreensShots(fileNamePrefix: String){
       var displayCount: UInt32 = 0;
       var result = CGGetActiveDisplayList(0, nil, &displayCount)
       if (result != CGError.success) {
           Logger.shared.log("error: \(result)")
           return
       }
       let allocated = Int(displayCount)
       let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
       result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)

       if (result != CGError.success) {
           Logger.shared.log("error: \(result)")
           return
       }

       guard let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
           Logger.shared.log("Unable to locate Desktop directory.")
           return
       }

       for i in 1...displayCount {
           let unixTimestamp = CreateTimeStamp()
           let fileUrl = URL(fileURLWithPath: fileNamePrefix + "_" + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
           let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
           let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
           let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!


           do {
               try jpegData.write(to: fileUrl, options: .atomic)
           }
           catch {Logger.shared.log("error: \(error)")}

           self.selectedFileUrl = fileUrl
       }
   }

    private func CreateTimeStamp() -> Int32
    {
        return Int32(Date().timeIntervalSince1970)
    }

    func createInput(transcribedText: String) {
        if model == STABLE_MODEL {
            chatState.messages.append(.message(Message(text: transcribedText, role: .User)))
        } else if model == MULTI_MODAL_MODEL {
            var content = [MultiModalMessageContent(text: transcribedText)]
            if let selectedFileUrl = self.selectedFileUrl {
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

    @ViewBuilder
    private func InputBox() -> some View {
        // can be enabled by setting Knobs.isTextInputEnabled to true, use for debugging only
        if Knobs.isTextInputEnabled {
            ChatInputView { newMessage in
                // Append new message to the array
                self.sendRequestToLargeLanguageModel(transcribedText: newMessage)
            }
        }
    }

    @ViewBuilder
    private func llamaButtonPlayground() -> some View {
        if Knobs.enableLlamaClientPlayground {
            Button(action: {
                testLlamaClient()
            }) {
                HStack {
                    Image(systemName: "scroll")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .help("test llama query")

                    Text(
                        llamaResponse
                    )
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    func testLlamaClient() {
        do {
            // Initialize the client with the callback
            let llamaClient = try LlamaClient(withCallback: mainCallback)

            // Send a query
            if let response = llamaClient.query(input_text: "State the meaning of life") {
                llamaResponse = response
                print("response: \(response)")
            } else {
                print("Model failed to return a response.")
            }
        } catch {
            print("Error initializing LlamaClient: \(error)")
        }
    }

    func mainCallback(_ str: String, _ time: Double) -> Bool {
        return false;
    }

}
