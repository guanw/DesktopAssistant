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
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var messages: [ChatMessage] = []
    @State private var showFloatingWindow = false
    @State private var selectedFileUrl: URL? = nil
    @State private var isAttachPageClickableHovered = false
    @State private var isScreenshotClickableHovered = false
    @State private var waitingForReply = false
    private let apiClient = GroqAPIClient(apiKey: "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", model: model)

    var body: some View {
        VStack() {
            KeyPressResponder {
                handleKeyPress()
            }
            .frame(width: 0, height: 0)
            
            chatHistory()

            HStack () {
                imageAttachment()

                screenshotButton()
            }


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
                self.waitingForReply = true;
                apiClient.sendChatCompletionRequest(messages: messages) { result in
                    switch result {
                    case .success(let result):
                        messages.append(.message(Message(text: result, role: .System)))
                        TextToSpeech.shared.speak(result)
                    case .failure(let error):
                        messages.append(.message(Message(text: "Error: \(error.localizedDescription)", role: .System)))
                    }
                    self.waitingForReply = false;
                }

                // reset
                transcribedText = ""
                self.selectedFileUrl = nil
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

                        self.waitingForReply ? ThreeDotsLoading()
                            .frame(width: 100, height: 30) : nil
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
            if isRecording && transcribedText.isEmpty {
                ThreeDotsLoading() // Show loading animation
                    .frame(width: 100, height: 30)
            } else if (isRecording) {
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

    private func recordingStateIndicator() -> some View {
        return HStack(spacing: 20) {
            if isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
            } else {
                Text("Press CMD+l and start talking, press again to stop")
                    .foregroundColor(.gray)
            }
        }.padding()
    }
    
    func createInput(transcribedText: String) {
        if model == STABLE_MODEL {
            messages.append(.message(Message(text: transcribedText, role: .User)))
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
            messages.append(
                .multiModalMessage(
                    MultiModalMessage(role: .User, content: content)
                )
            )

        }
    }
}
