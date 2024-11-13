import Foundation

class GroqAPIClient {
    private let apiKey: String
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
//    private let baseURL = "https://www.google.com/?q=hello"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendChatCompletionRequest(message: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Set up the URL
        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Define the JSON body
        let body: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": message
                ]
            ],
            "model": model
        ]
        
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
    
    func parseChatCompletionResponse(data: Data) throws -> String {
        let decoder = JSONDecoder()
        let response = try decoder.decode(GroqChatCompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? "failed to find any choices"
    }
}
