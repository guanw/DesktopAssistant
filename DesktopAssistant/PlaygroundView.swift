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

    func testLlamaClient() {
        do {
            // Initialize the client with the callback
            let llamaClient = try LlamaClient(withCallback: mainCallback)

            // Send a query
            if let response = llamaClient.query(input_text: "State the meaning of life") {
                playgroundState.llamaResponse = response
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
