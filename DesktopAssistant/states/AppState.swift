import Combine

let MULTI_MODAL_MODEL = "llama-3.2-90b-vision-preview"
let STABLE_MODEL = "llama3-8b-8192"
let model = MULTI_MODAL_MODEL

class AppState {
    static let shared = AppState()
    var apiClient: GroqAPIClient = GroqAPIClient(apiKey: "", model: model)
}

