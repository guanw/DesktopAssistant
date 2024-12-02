import Foundation

class GroqAPIClient {
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    func sendChatCompletionRequest(messages: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        // Set up the URL
        guard let url = URL(string: baseURL) else {
            Logger.shared.log("Invalid URL: " + baseURL)
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = self.formatBody(messages: messages)

        // Convert the JSON body to data
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])
                completion(.failure(error))
                return
            }

            // Check and parse the response data
            if let data = data {
                do {
                    let res = try self.parseChatCompletionResponse(data: data)
                    completion(.success(res))
                } catch {
                    completion(.failure(error))
                }
            }
        }

        // Start the task
        task.resume()
    }

    func formatBody(messages: [ChatMessage]) -> [String: Any] {
        var formattedMessages = self.formatMessages(messages: messages)
        formattedMessages = self.appendAssistantMessage(body: formattedMessages, latestMessage: messages.last)
        return [
            "messages": formattedMessages,
            "model": self.model
        ]
    }

    func formatMessages(messages: [ChatMessage]) -> [[String : Any]] {
        return messages.map { (message: ChatMessage) in
            switch message {
            case .message(let message):
                return [
                    "role": message.role.rawValue,
                    "content": message.text
                ]
            case .multiModalMessage(let multiModalMessage):
                return [
                    "role": multiModalMessage.role.rawValue,
                    "content": multiModalMessage.content.map { content in
                        var res: [String: Any] = ["type": content.type.rawValue]
                        if let text = content.text {
                            res["text"] = text
                        } else if let imageUrl = content.imageUrl {
                            res["image_url"] = ["url": imageUrl]
                        }
                        return res
                    }
                ]
            }
        }
    }

    func appendAssistantMessage(body: [[String : Any]], latestMessage: ChatMessage?) -> [[String : Any]] {
        var messages = body

        // add assistant to messages
        var lastMessageUnzipped = ""
        switch latestMessage {
        case .message(let message):
            lastMessageUnzipped = message.text
        case .multiModalMessage(let multiModalMessage):
            lastMessageUnzipped = multiModalMessage.content.first?.text ?? ""
        default:
            lastMessageUnzipped = ""
        }
        if (lastMessageUnzipped.lowercased().contains("code")) {
            messages.append(["role": "assistant", "content": "make sure if the user is asking you to generate some code, just output the code itself, don't add any non-code context. But please only do this if you see keyword code from message"])
        } else if (lastMessageUnzipped.lowercased().contains("remind me")) {
            CommandParser.isReminderCommand = true;
            let prunedLastMessage = lastMessageUnzipped.lowercased().replacingOccurrences(of: "remind me", with: "");
            let notificationCommand = "osascript -e 'display notification \"\(prunedLastMessage)\" with title \"DesktopAssistant Reminder\"'"
            messages.append(["role": "system", "content": """
                The user wants to schedule a task. Generate a valid cron job command
                based on the user's request. The response must include only the cron job syntax
                (no explanation) and an example command.

                Example:
                Request: "Remind me to drink water every hour."
                Response: "0 * * * *", "Drink water"

                Request: "\(lastMessageUnzipped)"
                Response:
            """])
        }

        return messages;
    }

    func parseChatCompletionResponse(data: Data) throws -> String {
        let decoder = JSONDecoder()
        let response = try decoder.decode(GroqChatCompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? "failed to find any choices"
    }
}
