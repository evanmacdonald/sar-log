import SwiftData
import XCTest
@testable import SARLog

final class SARLogPDFReportTests: XCTestCase {
    @MainActor
    func testReportMapsHeaderRowsAndNotesAppendix() throws {
        let store = try makeRepository()
        let task = try store.repository.createTask(
            taskNumber: "2026-123",
            subjectName: "Taylor Example",
            location: "Eagle Ridge",
            scribeName: "Evan",
            notes: "Subject requested family notification.",
            createdAt: Date(timeIntervalSince1970: 100),
            closedAt: Date(timeIntervalSince1970: 500)
        )

        let report = SARLogPDFReportBuilder.makeReport(
            task: task,
            timelineEvents: [],
            vitalsEntries: [],
            generatedAt: Date(timeIntervalSince1970: 600)
        )

        XCTAssertEqual(report.taskNumber, "2026-123")
        XCTAssertEqual(report.taskName, "Taylor Example")
        XCTAssertEqual(report.logKeeper, "Evan")
        XCTAssertEqual(report.location, "Eagle Ridge")
        XCTAssertEqual(report.periodStart, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(report.periodEnd, Date(timeIntervalSince1970: 500))
        XCTAssertTrue(report.hasNotesAppendix)
    }

    @MainActor
    func testReportCombinesTimelineAndVitalsAsChronologicalLogRows() throws {
        let store = try makeRepository()
        let task = try store.repository.createTask(subjectName: "Taylor Example")
        let laterEvent = try store.repository.createTimelineEvent(
            for: task,
            label: "Arrived staging",
            timestamp: Date(timeIntervalSince1970: 300)
        )
        let vitals = try store.repository.createVitalsEntry(
            for: task,
            timestamp: Date(timeIntervalSince1970: 200)
        )
        try store.repository.updateVitalsEntry(vitals, set: \.heartRate, to: 72)
        try store.repository.updateVitalsEntry(vitals, set: \.systolicBloodPressure, to: 120)
        try store.repository.updateVitalsEntry(vitals, set: \.diastolicBloodPressure, to: 80)
        try store.repository.updateVitalsEntry(vitals, set: \.oxygenSaturation, to: 98)
        try store.repository.updateVitalsEntry(vitals, set: \.gcsEye, to: 4)
        try store.repository.updateVitalsEntry(vitals, set: \.gcsVerbal, to: 5)
        try store.repository.updateVitalsEntry(vitals, set: \.gcsMotor, to: 6)
        let earliestEvent = try store.repository.createTimelineEvent(
            for: task,
            label: "Callout from ECC",
            timestamp: Date(timeIntervalSince1970: 100)
        )

        let report = SARLogPDFReportBuilder.makeReport(
            task: task,
            timelineEvents: try store.repository.timelineEvents(for: task),
            vitalsEntries: try store.repository.vitalsEntries(for: task),
            generatedAt: Date(timeIntervalSince1970: 400)
        )

        XCTAssertEqual(report.rows.map(\.id), [earliestEvent.id, vitals.id, laterEvent.id])
        XCTAssertEqual(report.rows[0].subject, "Callout from ECC")
        XCTAssertTrue(report.rows[1].subject.contains("Vitals: HR 72"))
        XCTAssertTrue(report.rows[1].subject.contains("BP 120/80"))
        XCTAssertTrue(report.rows[1].subject.contains("SpO2 98%"))
        XCTAssertTrue(report.rows[1].subject.contains("GCS 15 (E4 V5 M6)"))
        XCTAssertEqual(report.rows[2].subject, "Arrived staging")
    }

    func testLayoutExpandsRowsToFitLongSubjectText() {
        let shortHeight = SARLogPDFLayout.rowHeight(subject: "Vitals: HR 72")
        let longHeight = SARLogPDFLayout.rowHeight(
            subject: String(repeating: "Vitals detail with enough words to wrap. ", count: 12)
        )

        XCTAssertEqual(shortHeight, SARLogPDFLayout.minRowHeight)
        XCTAssertGreaterThan(longHeight, shortHeight)
    }

    func testLayoutPaginatesRowsWithoutDroppingEntries() {
        let rows = (0..<10).map { index in
            SARLogPDFLogRow(
                id: UUID(),
                timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                subject: "Entry \(index)",
                source: .timeline
            )
        }

        let pages = SARLogPDFLayout.paginateRows(
            rows,
            availableHeight: SARLogPDFLayout.minRowHeight * 3
        )

        XCTAssertEqual(pages.count, 4)
        XCTAssertEqual(pages.flatMap { $0.map(\.row.id) }, rows.map(\.id))
    }

    func testLayoutPaginatesLongNotesWithoutDroppingText() {
        let notes = String(repeating: "Long appendix note with enough words to wrap across the page. ", count: 1_000)
        let trimmedLength = (notes.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).length
        let ranges = SARLogPDFLayout.noteRanges(for: notes)

        XCTAssertGreaterThan(ranges.count, 1)
        XCTAssertEqual(ranges.reduce(0) { $0 + $1.length }, trimmedLength)
    }

    @MainActor
    func testRendererEmitsPDFDataAndCountsNotesAppendixPage() throws {
        let store = try makeRepository()
        let task = try store.repository.createTask(
            taskNumber: "2026-123",
            subjectName: "Taylor Example",
            scribeName: "Evan",
            notes: "Appendix note",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        try store.repository.createTimelineEvent(
            for: task,
            label: "Callout from ECC",
            timestamp: Date(timeIntervalSince1970: 120)
        )
        let report = SARLogPDFReportBuilder.makeReport(
            task: task,
            timelineEvents: try store.repository.timelineEvents(for: task),
            vitalsEntries: [],
            generatedAt: Date(timeIntervalSince1970: 200)
        )

        let data = SARLogPDFRenderer.data(for: report)

        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
        XCTAssertGreaterThan(data.count, 1_000)
        XCTAssertEqual(SARLogPDFLayout.totalPageCount(for: report), 2)
    }

    @MainActor
    private func makeRepository() throws -> RepositoryStore {
        let container = try SARLogModelContainer.inMemory()
        return RepositoryStore(
            container: container,
            repository: TaskRepository(context: container.mainContext)
        )
    }
}

private struct RepositoryStore {
    let container: ModelContainer
    let repository: TaskRepository
}
