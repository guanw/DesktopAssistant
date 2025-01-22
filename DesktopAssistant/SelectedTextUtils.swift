import AppKit

class SelectedTextUtils {
    static func getSelectedTextFromPasteBoard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
