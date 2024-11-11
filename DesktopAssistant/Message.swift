import Foundation

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isSender: Bool // true for sender, false for receiver
}
