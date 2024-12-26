import SwiftUI

struct PlaygroundView: View {
    @ObservedObject var playgroundState : PlaygroundState
    var body: some View {
        VStack {
            Text("Playground view")
                .font(.largeTitle)
                .padding()

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

    }

    func testLlamaClient(prompt: String = "state the meaning of life") {
        do {
            // Initialize the client with the callback
            let llamaClient = try LlamaClient()

            llamaClient.sendGenerateRequest(prompt: prompt) { result in
                switch result {
                case .success(let data):
                    guard let responseString = String(data: data, encoding: .utf8) else {
                        print("Failed to convert data to string")
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
                                print("Failed to decode JSON object: \(error)")
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        playgroundState.llamaResponse = concatenatedResponse
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error initializing LlamaClient: \(error)")
        }
    }

    func mainCallback(_ str: String, _ time: Double) -> Bool {
        return false;
    }
}
