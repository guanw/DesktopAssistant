struct OllamaSingleResponse: Codable {
    let model: String
    let created_at: String
    let response: String
    let done: Bool
}
