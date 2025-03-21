import Foundation

// Define the request payload structure
struct GenerateRequest: Codable {
    let model: String
    let prompt: String
}

class LlamaClient {
    @Published var url: URL?

    // Define the function to send the POST request
    func sendGenerateRequest(prompt: String, completion: @escaping (Result<Data, Error>) -> Void) {
        Logger.shared.log("Started Send Prompt")
        guard !prompt.isEmpty else { return }

        // Create the request payload
        let requestBody = GenerateRequest(model: "deepseek-r1:8b", prompt: prompt)

        // Convert the payload to JSON data
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(NSError(domain: "Encoding error", code: -1, userInfo: nil)))
            return
        }

        guard let url = self.url else {
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Create the URL session
        let session = URLSession.shared

        // Send the request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.log("Error: \(error.localizedDescription)")
                return
            }

            guard let _ = response as? HTTPURLResponse else {
                let error = NSError(domain: "HTTP Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                let error = NSError(domain: "No Data", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
            }
        }

        task.resume()
        return
    }

    init() {
        // Define the server endpoint
        let urlString = "http://127.0.0.1:11434/api/generate"
        // Safely unwrap the URL constructed from the urlString
        self.url = URL(string: urlString)
    }
}

