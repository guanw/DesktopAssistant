import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechManager = SpeechToTextManager()
    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var messages: [Message] = []

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Recognition")
                .font(.largeTitle)
                .padding()
            
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
            
            TextEditor(text: .constant(transcribedText))
                .font(.body)
                .frame(height: 50)
                .padding()
                .border(Color.gray, width: 1)

            HStack(spacing: 20) {
                Button(action: {
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
                }) {
                    Text(isRecording ? "Stop" : "Start")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                
                if isRecording {
                    Text("Recording...")
                        .foregroundColor(.red)
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
