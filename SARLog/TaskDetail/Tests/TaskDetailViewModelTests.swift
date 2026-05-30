import SwiftData
import XCTest
@testable import SARLog

final class TaskDetailViewModelTests: XCTestCase {
    @MainActor
    func testFieldUpdatesPersistImmediately() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)

        model.updateTaskNumber("2026-001")
        model.updateSubjectName("Taylor Example")
        model.updateLocation("49.123, -123.456")
        model.updateScribeName("Evan")
        model.updateNotes("Reached subject at creek crossing.")

        let fetched = try XCTUnwrap(repository.task(id: task.id))
        XCTAssertEqual(fetched.taskNumber, "2026-001")
        XCTAssertEqual(fetched.subjectName, "Taylor Example")
        XCTAssertEqual(fetched.location, "49.123, -123.456")
        XCTAssertEqual(fetched.scribeName, "Evan")
        XCTAssertEqual(fetched.notes, "Reached subject at creek crossing.")
    }

    @MainActor
    func testMapsURLReflectsCurrentLocation() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask(location: "Staging")
        let model = TaskDetailViewModel(task: task, repository: repository)

        XCTAssertNil(model.mapsURL)

        model.updateLocation("49.123, -123.456")

        XCTAssertEqual(model.mapsURL?.host, "maps.apple.com")
    }

    @MainActor
    func testTimelineEventsLoadOldestFirst() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let latest = try repository.createTimelineEvent(
            for: task,
            label: "On scene",
            timestamp: Date(timeIntervalSince1970: 300)
        )
        let earliest = try repository.createTimelineEvent(
            for: task,
            label: "Callout from ECC",
            timestamp: Date(timeIntervalSince1970: 100)
        )

        let model = TaskDetailViewModel(task: task, repository: repository)

        XCTAssertEqual(model.timelineEvents.map(\.id), [earliest.id, latest.id])
    }

    @MainActor
    func testPredefinedTimelineEventsMatchCharterLabels() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)

        XCTAssertEqual(
            model.predefinedTimelineEvents.map(\.label),
            [
                "Callout from ECC",
                "Left hall",
                "Arrived staging",
                "Departed staging",
                "On scene",
                "Returning to base"
            ]
        )
    }

    @MainActor
    func testAddPredefinedTimelineEventPersistsImmediatelyAndRefreshesTimeline() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let timestamp = Date(timeIntervalSince1970: 700)

        model.addPredefinedTimelineEvent(
            try XCTUnwrap(model.predefinedTimelineEvents.first),
            at: timestamp
        )

        let event = try XCTUnwrap(model.timelineEvents.first)
        XCTAssertEqual(event.taskId, task.id)
        XCTAssertEqual(event.label, "Callout from ECC")
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertFalse(event.isCustom)
        XCTAssertEqual(try repository.timelineEvents(for: task).map(\.id), [event.id])
    }
}
