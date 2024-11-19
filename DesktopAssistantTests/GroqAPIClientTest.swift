import Testing
import XCTest
@testable import DesktopAssistant

enum CustomError: Error {
    case genericError(message: String)
}

struct GroqAPIClientTest {
    let apiClient = GroqAPIClient(apiKey: "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", model: STABLE_MODEL)
    @Test func example() async throws {
        XCTAssertEqual(1 + 1, 2)
    }
    
    @Test func testFormatMessagesWithMessages() async throws {
        let messages: [ChatMessage] = [
            .message(Message(text: "test1", role: Role.User)),
            .message(Message(text: "test2", role: Role.System)),
        ]
        let res = apiClient.formatMessages(messages: messages)
        XCTAssertEqual(res.count, 2)
        if let text = res[0]["content"] as? String {
            XCTAssertEqual(text, "test1")
        } else {
            throw CustomError.genericError(message: "text should be casted as string for the message")
        }
    }

    @Test func testFormatMessagesWithMultiModalMessages() async throws {
        let messages: [ChatMessage] = [
            .multiModalMessage(MultiModalMessage(role: Role.User, content: [MultiModalMessageContent(text: "test")])),
            .multiModalMessage(MultiModalMessage(role: Role.System, content: [MultiModalMessageContent(imageUrl: "test_url")])),
        ]
        let res = apiClient.formatMessages(messages: messages)
        XCTAssertEqual(res.count, 2)
        
        if let textContent = res[0]["content"] as? [[String: Any]] {
            XCTAssertEqual(textContent.count, 1)
            XCTAssertEqual(textContent[0]["type"] as? String, "text") // Check the type
            XCTAssertEqual(textContent[0]["text"] as? String, "test") // Check the text content
        } else {
            throw CustomError.genericError(message: "content should be casted as [[String: Any]] for the message")
        }
    }
}
