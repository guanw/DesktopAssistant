import SwiftUI

struct InferenceBackendSelectionView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var knobs: Knobs = Knobs.shared
    let aiModels = ["Ollama", "Groq"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Backend", selection: $appState.selectedModel) {
                ForEach(aiModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle()) // Use the native dropdown menu style

            if knobs.showInferenceModel {
                Text("Selected Inference Backend: \(appState.selectedModel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}
