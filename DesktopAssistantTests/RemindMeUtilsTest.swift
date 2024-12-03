import Testing
import XCTest
@testable import DesktopAssistant

class RemindMeUtilsTest {
    private let prefix = "remind me to drink water"

    @Test func testParseTimeFromTextWithRelativeTime() async throws {
        let key = "in 2 hours"
        let result = RemindMeUtils.parseTimeFromText(
            text: prefix + key
        )
        XCTAssertEqual(result?.hours, 2)
        XCTAssertEqual(result?.minutes, 0)
    }

    @Test func testParseTimeFromTextWithAbsoluteTime() async throws {
        let key = "at 4 pm tomorrow"
        let testCurrentDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 2, hour: 14, minute: 0))!
        let result = RemindMeUtils.parseTimeFromText(
            text: prefix + key, currentDate: testCurrentDate
        )
        XCTAssertEqual(result?.hours, 26)
        XCTAssertEqual(result?.minutes, 0)
    }

    @Test func testParseTimeFromTextWithAbsoluteTime2() async throws {
        let key = "at 4 pm on December 3rd, 2024"
        let testCurrentDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 2, hour: 14, minute: 0))!
        let result = RemindMeUtils.parseTimeFromText(
            text: prefix + key, currentDate: testCurrentDate
        )
        XCTAssertEqual(result?.hours, 26)
        XCTAssertEqual(result?.minutes, 0)
    }
}

