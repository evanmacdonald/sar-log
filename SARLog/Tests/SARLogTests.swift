import XCTest
@testable import SARLog

final class SARLogTests: XCTestCase {
    func testReadinessMessageMatchesTaskState() {
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: false), "Ready for task logging.")
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: true), "Task logging in progress.")
    }

    @MainActor
    func testAppAndRootViewBuild() {
        _ = SARLogApp().body
        _ = ContentView().body

        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "SAR Log")
    }
}
