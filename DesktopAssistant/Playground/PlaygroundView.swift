import SwiftUI

struct PlaygroundView: View {
    @ObservedObject var playgroundState : PlaygroundState
    @StateObject private var monitor = SelectionMonitor()

    var body: some View {
        VStack {
            Text("Playground view")
                .font(.largeTitle)
                .padding()

            if let contextText = monitor.selectedText, !contextText.isEmpty {
                Text("Selected Text: \(contextText)")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            } else {
                Text("No text selected.")
                    .foregroundColor(.gray)
            }

            Button(action: {
                testLlamaClient()
            }) {
                VStack {
                    Image(systemName: "scroll")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .help("test llama query")

                        ScrollView {
                            Text(
                                playgroundState.llamaResponse
                            )
                        }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }.frame(width: Constants.CHAT_WIDTH, height: 400)
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }

    }

    func testLlamaClient(prompt: String = "state the meaning of life") {
        do {
            // Initialize the client with the callback
            let llamaClient = try LlamaClient()

            llamaClient.sendGenerateRequest(prompt: prompt) { result in
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
                        playgroundState.llamaResponse = concatenatedResponse
                    }
                case .failure(let error):
                    Logger.shared.log("Error: \(error.localizedDescription)")
                }
            }
        } catch {
            Logger.shared.log("Error initializing LlamaClient: \(error)")
        }
    }

    func mainCallback(_ str: String, _ time: Double) -> Bool {
        return false;
    }
}
