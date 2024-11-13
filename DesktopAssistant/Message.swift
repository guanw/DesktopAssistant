import Foundation

enum Role: String {
    case User = "user"
    case System = "system"
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let role: Role
}
