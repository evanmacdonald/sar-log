import XCTest
@testable import SARLog

final class SARLogTests: XCTestCase {
    func testReadinessMessageMatchesTaskState() {
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: false), "Ready for task logging.")
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: true), "Task logging in progress.")
    }
}
