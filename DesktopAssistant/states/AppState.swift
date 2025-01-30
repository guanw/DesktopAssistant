import Combine

let MULTI_MODAL_MODEL = "llama-3.2-90b-vision-preview"
let STABLE_MODEL = "llama3-8b-8192"
let DEEPSEEK_MODEL = "deepseek-r1-distill-llama-70b"
let model = DEEPSEEK_MODEL

class AppState: ObservableObject {
    static let shared = AppState()
    var groqApiClient: GroqAPIClient = GroqAPIClient(apiKey: "", model: model)
    var shouldTranscribeToAudio = true
    var shouldEnablePasteBoard = false
    @Published var selectedModel: String = "Ollama"
}

