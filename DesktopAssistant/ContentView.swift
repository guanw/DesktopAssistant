import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var isAuthorized = false
    @State private var showFloatingWindow = false
    

    var body: some View {
        VStack() {

            InferenceBackendSelectionView(appState: AppState.shared)

            ChatHistory(chatState: ChatState.shared)

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
        .frame(width: 500, height: 600)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onAppear {
            speechManager.requestAuthorization { authorized in
                isAuthorized = authorized
            }
        }
    }

    public static func sendRequestToLargeLanguageModel(transcribedText: String) {
        if (!transcribedText.isEmpty) {
            ContentView.createInput(transcribedText: transcribedText)
            ChatState.shared.waitingForReply = true;
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

                // reset
                DispatchQueue.main.async {
                    ChatState.shared.waitingForReply = false;
                    ChatState.shared.transcribedText = ""
                }

                self.cleanupTempScreenshotFile()
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
            DispatchQueue.main.async {
                ChatState.shared.messages.append(.message(Message(text: transcribedText, role: .User)))
            }
        } else if model == MULTI_MODAL_MODEL {
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
            DispatchQueue.main.async {
                ChatState.shared.messages.append(
                    .multiModalMessage(
                        MultiModalMessage(role: .User, content: content)
                    )
                )
            }
        }
    }
}
