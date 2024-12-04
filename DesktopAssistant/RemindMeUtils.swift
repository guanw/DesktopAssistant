import Foundation
import Cocoa
import UserNotifications

class RemindMeUtils {
    static func parseTimeFromText(text: String, currentDate: Date = Date()) -> (hours: Int, minutes: Int)? {
        let calendar = Calendar.current

        // Detect relative time expressions using regex
        let regex = try! NSRegularExpression(pattern: "in\\s(\\d+)\\s(hours?|minutes?)", options: .caseInsensitive)
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        if let match = matches.first {
            let numberRange = Range(match.range(at: 1), in: text)!
            let unitRange = Range(match.range(at: 2), in: text)!

            if let number = Int(text[numberRange]) {
                let unit = text[unitRange].lowercased()
                if unit.starts(with: "hour") {
                    return (hours: number, minutes: 0)
                } else if unit.starts(with: "minute") {
                    return (hours: 0, minutes: number)
                }
            }
        }

        // Use NSDataDetector to detect absolute date/time expressions
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        if let match = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)).first,
           let detectedDate = match.date {
            let components = calendar.dateComponents([.hour, .minute], from: currentDate, to: detectedDate)
            if let hours = components.hour, let minutes = components.minute {
                return (hours, minutes)
            }
        }

        return nil
    }

    static func scheduleNotif(text: String, timeTuple: (hours: Int, minutes: Int)) {
        var notificationCenter = UNUserNotificationCenter.current()

        // Check if notification permissions are granted
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                // Request permission
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        Logger.shared.log("Notification permission granted.")
                    } else {
                        Logger.shared.log("Notification permission denied.")
                    }
                }
            }
        }

        // Configure the content of the notification
        let content = UNMutableNotificationContent()
        content.title = "Desktop Assistant"
        content.body = text
        content.sound = UNNotificationSound.default

        // Set the trigger to occur every Tuesday at 2pm
        let currentDate = Date()
        let targetDate = Calendar.current.date(
            byAdding: .minute,
            value: timeTuple.minutes,
            to: currentDate
        )!
        let targetDateWithHours = Calendar.current.date(
            byAdding: .hour,
            value: timeTuple.hours,
            to: targetDate
        )!
        let targetDateComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: targetDateWithHours)

        // Create a recurring trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: targetDateComponents, repeats: false)

        // Create a notification request with a unique identifier
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        // Add the notification request to the notification center
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.log("Error scheduling notification: \(error.localizedDescription)")
            } else {
                Logger.shared.log("Notification scheduled successfully.")
            }
        }
    }

}
