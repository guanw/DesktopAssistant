import Combine
import Foundation

class SelectionMonitor: ObservableObject {
    @Published var selectedText: String?

    private var timer: Timer?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            let val = SelectedTextUtils.getSelectedTextFromPasteBoard()
            self?.selectedText = val
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
