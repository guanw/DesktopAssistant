import Foundation
import AppKit

struct NotificationRecord: Codable {
    let id: String
    let title: String
    let body: String
    let scheduledTime: Date
}

class NotificationStore {
    public static let key = "NotificationRecords"

    static func save(_ record: NotificationRecord) {
        var records = fetchAll()
        records.append(record)
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func fetchAll() -> [NotificationRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([NotificationRecord].self, from: data) else {
            return []
        }
        let currentTime = Date()
        return records.filter { $0.scheduledTime > currentTime }
    }
}
