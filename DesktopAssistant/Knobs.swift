import Combine

class Knobs: ObservableObject {
    static let shared = Knobs()

    @Published var isTextInputEnabled: Bool = false;
}

