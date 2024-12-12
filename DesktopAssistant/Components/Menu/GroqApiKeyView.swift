import SwiftUI

struct GroqApiKeyView: View {
    @State private var apiKey: String = ""
    var onSubmit: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Groq API Key")
                .font(.headline)

            TextField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save") {
                onSubmit(apiKey)
            }
            .padding()
        }
        .padding()
    }
}
