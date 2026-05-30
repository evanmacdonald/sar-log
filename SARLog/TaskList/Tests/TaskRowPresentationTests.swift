import XCTest
@testable import SARLog

final class TaskRowPresentationTests: XCTestCase {
    func testTitlePrefersTaskNumber() {
        XCTAssertEqual(
            TaskRowPresentation.title(taskNumber: "2026-001", subjectName: "Taylor"),
            "2026-001"
        )
    }

    func testTitleFallsBackToSubjectWhenNumberBlank() {
        XCTAssertEqual(
            TaskRowPresentation.title(taskNumber: "   ", subjectName: "Taylor"),
            "Taylor"
        )
    }

    func testTitleFallsBackToPlaceholderWhenEmpty() {
        XCTAssertEqual(
            TaskRowPresentation.title(taskNumber: "", subjectName: "  "),
            "Untitled task"
        )
    }

    func testSubtitleShowsSubjectOnlyWhenNumberIsTitle() {
        XCTAssertEqual(
            TaskRowPresentation.subtitle(taskNumber: "2026-001", subjectName: "Taylor"),
            "Taylor"
        )
        XCTAssertNil(TaskRowPresentation.subtitle(taskNumber: "", subjectName: "Taylor"))
        XCTAssertNil(TaskRowPresentation.subtitle(taskNumber: "2026-001", subjectName: ""))
    }
}
