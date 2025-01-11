import Combine

class Knobs: ObservableObject {
    static let shared = Knobs()

    @Published var isTextInputEnabled: Bool = true;
    @Published var showInferenceModel: Bool = true;
}

