import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var isAuthorized = false
    @State private var showFloatingWindow = false
    

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 16) {

                    InferenceBackendSelectionView(appState: AppState.shared)

                    ChatHistory(chatState: ChatState.shared, containerSize: geometry.size)

                    HStack () {
                        ImageAttachment(imageState: ImageState.shared)

                        ScreenshotButton(imageState: ImageState.shared)
                    }

                    TranscribedText(
                        recordingState: RecordingState.shared,
                        chatState: ChatState.shared
                    )

                    RecordingStateIndicator(recordingState: RecordingState.shared)

                    if !isAuthorized {
                        Text("Please enable speech recognition permission in System Settings")
                            .foregroundColor(.red)
                    }

                    InputBox(sendRequest: ContentView.sendRequestToLargeLanguageModel)
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .onAppear {
                    speechManager.requestAuthorization { authorized in
                        isAuthorized = authorized
                    }
                }
            }
        }
    }

    public static func sendRequestToLargeLanguageModel(transcribedText: String) {
        if (!transcribedText.isEmpty) {
            ContentView.createInput(transcribedText: transcribedText)
            ChatState.shared.waitingForReply = true;
            if (AppState.shared.selectedModel == "Ollama") {
                // use Ollama as backend
                // TODO enable chat history to prompt
                AppState.shared.ollamaClient
                    .sendGenerateRequest(prompt: transcribedText) { result in
                    switch result {
                    case .success(let data):
                        guard let responseString = String(data: data, encoding: .utf8) else {
                            Logger.shared.log("Failed to convert data to string")
                            return
                        }
                        let jsonStrings = responseString.split(separator: "\n")

                        var concatenatedResponse = ""

                        for jsonString in jsonStrings {
                            // Convert each JSON string back to Data for decoding
                            if let jsonData = jsonString.data(using: .utf8) {
                                do {
                                    // Decode the JSON string into an OllamaSingleResponse
                                    let singleResponse = try JSONDecoder().decode(OllamaSingleResponse.self, from: jsonData)
                                    // Append the `response` field to the result
                                    concatenatedResponse += singleResponse.response
                                } catch {
                                    Logger.shared.log("Failed to decode JSON object: \(error)")
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            self.parseSuccessReply(messages: ChatState.shared.messages, result: concatenatedResponse, transcribedText: transcribedText)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            ChatState.shared.messages.append(.message(Message(text: "Error: \(error)", role: .System)))
                        }
                    }
                    // reset
                    DispatchQueue.main.async {
                        ChatState.shared.waitingForReply = false;
                        ChatState.shared.transcribedText = ""
                    }
                }
            } else {
                // use groq api as backend
                AppState.shared.groqApiClient
                    .sendChatCompletionRequest(
                        messages: ChatState.shared.messages,
                        latestMessage: transcribedText
                    ) { result in
                    switch result {
                    case .success(let result):
                        self.parseSuccessReply(messages: ChatState.shared.messages, result: result, transcribedText: transcribedText)
                    case .failure(let error):
                        DispatchQueue.main.async {
                            ChatState.shared.messages.append(.message(Message(text: "Error: \(error)", role: .System)))
                        }
                    }

                    self.cleanupTempScreenshotFile()
                    // reset
                    DispatchQueue.main.async {
                        ChatState.shared.waitingForReply = false;
                        ChatState.shared.transcribedText = ""
                    }
                }
            }
        }
    }

    static private func cleanupTempScreenshotFile() {
        let fileManager = FileManager.default
        if (ImageState.shared.selectedFileUrl == nil) {
            return
        }
        do {
            defer {
                ImageState.shared.selectedFileUrl = nil
            }
            if fileManager.fileExists(atPath: ImageState.shared.selectedFileUrl!.path) {
                try fileManager.removeItem(at: ImageState.shared.selectedFileUrl!)
                Logger.shared.log("File deleted successfully.")
            } else {
                Logger.shared.log("File does not exist at \(ImageState.shared.selectedFileUrl!.path).")
            }
        } catch {
            Logger.shared.log("Failed to delete file: \(error.localizedDescription)")
        }

    }

    static private func parseSuccessReply(messages: [ChatMessage], result: String, transcribedText: String) {
        if (CommandParser.isReminderCommand) {
            Logger.shared.log("reminder scheduled result: \(result)")
            let timeTuple = RemindMeUtils.parseTimeFromText(text: transcribedText)
            if (timeTuple == nil) {
                DispatchQueue.main.async {
                    ChatState.shared.messages.append(.message(Message(text: "failed to extract hour and minute for reminder", role: .System)))
                }
                Logger.shared.log("failed to extract hour and minute for reminder")
                return
            }
            RemindMeUtils.scheduleNotif(text: result, timeTuple: timeTuple!)
            DispatchQueue.main.async {
                ChatState.shared.messages.append(.message(Message(text: String(
                    format: "reminder scheduled in %d hour(s) and %d minute(s)",
                    timeTuple!.hours,
                    timeTuple!.minutes
                ), role: .System)))
            }
            return
        }
        DispatchQueue.main.async {
            ChatState.shared.messages.append(.message(Message(text: result, role: .System)))
        }
        TextToSpeech.shared.speak(result)
    }

    static func createInput(transcribedText: String) {
        if model == STABLE_MODEL {
            ChatState.shared.messages.append(.message(Message(text: transcribedText, role: .User)))
            if (
                AppState.shared.shouldEnablePasteBoard && !ChatState.shared.pasteBoardText.isEmpty
            ) {
                ChatState.shared.messages.append(.message(Message(text: ChatState.shared.pasteBoardText, role: .User)))
            }
        } else {
            var content = [MultiModalMessageContent(text: transcribedText)]
            if let selectedFileUrl = ImageState.shared.selectedFileUrl {
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
            ChatState.shared.messages.append(
                .multiModalMessage(
                    MultiModalMessage(role: .User, content: content)
                )
            )
            if (AppState.shared.shouldEnablePasteBoard && !ChatState.shared.pasteBoardText.isEmpty) {
                let content = [MultiModalMessageContent(text: ChatState.shared.pasteBoardText)]
                ChatState.shared.messages.append(.multiModalMessage(MultiModalMessage(role: .User, content: content)))
            }
        }
        ChatState.shared.pasteBoardText = ""
    }
}
