import Foundation

struct GroqChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    let systemFingerprint: String
    let xGroq: GroqInfo

    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
        case xGroq = "x_groq"
    }
}

struct Choice: Codable {
    let index: Int
    let message: GroqMessage
    let logprobs: String?
    let finishReason: String

    enum CodingKeys: String, CodingKey {
        case index, message, logprobs
        case finishReason = "finish_reason"
    }
}

struct GroqMessage: Codable {
    let role: String
    let content: String
}

struct Usage: Codable {
    let queueTime: Double
    let promptTokens: Int
    let promptTime: Double
    let completionTokens: Int
    let completionTime: Double
    let totalTokens: Int
    let totalTime: Double

    enum CodingKeys: String, CodingKey {
        case queueTime = "queue_time"
        case promptTokens = "prompt_tokens"
        case promptTime = "prompt_time"
        case completionTokens = "completion_tokens"
        case completionTime = "completion_time"
        case totalTokens = "total_tokens"
        case totalTime = "total_time"
    }
}

struct GroqInfo: Codable {
    let id: String
}
