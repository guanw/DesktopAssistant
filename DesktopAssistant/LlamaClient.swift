import Foundation

// Define the request payload structure
struct GenerateRequest: Codable {
    let model: String
    let prompt: String
}

class LlamaClient {


    // Define the function to send the POST request
    func sendGenerateRequest(prompt: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // API URL
        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        // Create the request payload
        let requestBody = GenerateRequest(model: "llama3.2", prompt: prompt)

        // Convert the payload to JSON data
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(NSError(domain: "Encoding error", code: -1, userInfo: nil)))
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
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "HTTP Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
                return
            }

            if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                completion(.success(data))
            } else {
                let error = NSError(domain: "No Data", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
            }
        }

        task.resume()
        return
    }

    init() throws {

    }
}

