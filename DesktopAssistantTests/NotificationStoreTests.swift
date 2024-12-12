import XCTest
@testable import DesktopAssistant

class NotificationStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: NotificationStore.key)
    }

    func testSaveNotificationRecord() {
        // Arrange
        let record = NotificationRecord(id: "1", title: "Test", body: "Body", scheduledTime: Date())

        // Act
        NotificationStore.save(record)

        // Assert
        let savedRecords = NotificationStore.fetchAll()
        XCTAssertEqual(savedRecords.count, 1)
        XCTAssertEqual(savedRecords.first?.id, record.id)
    }

    func testFetchAllNotificationRecords() {
        // Arrange
        let record1 = NotificationRecord(id: "1", title: "Test1", body: "Body1", scheduledTime: Date())
        let record2 = NotificationRecord(id: "2", title: "Test2", body: "Body2", scheduledTime: Date())
        NotificationStore.save(record1)
        NotificationStore.save(record2)

        // Act
        let records = NotificationStore.fetchAll()

        // Assert
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first?.id, record1.id)
        XCTAssertEqual(records.last?.id, record2.id)
    }

    func testRemoveNotificationRecord() {
        // Arrange
        let record1 = NotificationRecord(id: "1", title: "Test1", body: "Body1", scheduledTime: Date())
        let record2 = NotificationRecord(id: "2", title: "Test2", body: "Body2", scheduledTime: Date())
        NotificationStore.save(record1)
        NotificationStore.save(record2)

        // Act
        NotificationStore.remove(by: record1.id)

        // Assert
        let records = NotificationStore.fetchAll()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, record2.id)
    }

    func testRemoveNonExistentNotificationRecord() {
        // Arrange
        let record = NotificationRecord(id: "1", title: "Test", body: "Body", scheduledTime: Date())
        NotificationStore.save(record)

        // Act
        NotificationStore.remove(by: "non-existent-id")

        // Assert
        let records = NotificationStore.fetchAll()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, record.id)
    }

    func testFetchAllWhenNoRecordsExist() {
        // Act
        let records = NotificationStore.fetchAll()

        // Assert
        XCTAssertEqual(records.count, 0)
    }
}
