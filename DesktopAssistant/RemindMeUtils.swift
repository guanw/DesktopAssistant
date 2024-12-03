import Foundation
import SwiftDate


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

}
