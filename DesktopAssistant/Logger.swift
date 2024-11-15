import Foundation

class Logger {
    static let shared = Logger()  // Singleton instance for global access
    // file logs to /Users/{USERNAME}/Library/Containers/com.gui.DesktopAssistant/Data/Documents
    private let logFileName = "app_log.txt"
    private let maxLogFileSize: UInt64 = 5 * 1024 * 1024  // 5 MB file size limit

    private init() {
        // Create log file if it doesn't exist
        createLogFileIfNeeded()
    }

    // MARK: - Logging Methods

    func log(_ message: String) {
        let timestampedMessage = "\(Date()): \(message)"
        
        // Print to console
        print(timestampedMessage)
        
        // Write to file
        writeToLogFile(timestampedMessage)
    }

    // MARK: - File Handling

    private func createLogFileIfNeeded() {
        let fileURL = logFileURL()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
    }

    private func logFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(logFileName)
    }

    private func writeToLogFile(_ message: String) {
        let fileURL = logFileURL()
        
        // Check file size and remove if it exceeds max size
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64,
           fileSize > maxLogFileSize {
            // Remove the log file and create a new one
            try? FileManager.default.removeItem(at: fileURL)
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        // Append message to the log file
        if let data = (message + "\n").data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                // If the file cannot be opened for writing, create a new log file
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
}
