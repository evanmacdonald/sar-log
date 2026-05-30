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
        XCTAssertEqual(model.predefinedTimelineEvents.map(\.id), model.predefinedTimelineEvents.map(\.label))
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

    @MainActor
    func testAddCustomTimelineEventMarksEventCustomAndRefreshesTimeline() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)

        let event = try XCTUnwrap(
            model.addCustomTimelineEvent(label: "Helicopter overhead", at: Date(timeIntervalSince1970: 400))
        )

        XCTAssertTrue(event.isCustom)
        XCTAssertEqual(event.label, "Helicopter overhead")
        XCTAssertEqual(model.timelineEvents.map(\.id), [event.id])
    }

    @MainActor
    func testEditingTimelineEventLabelPersistsImmediately() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let event = try XCTUnwrap(model.addCustomTimelineEvent(label: "Draft", at: Date(timeIntervalSince1970: 100)))

        model.updateTimelineEvent(event, label: "Subject located")

        XCTAssertEqual(model.timelineEvents.first?.label, "Subject located")
        XCTAssertEqual(try repository.timelineEvents(for: task).first?.label, "Subject located")
    }

    @MainActor
    func testBackdatingTimelineEventReordersTheList() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let first = try XCTUnwrap(model.addCustomTimelineEvent(label: "First", at: Date(timeIntervalSince1970: 100)))
        let second = try XCTUnwrap(model.addCustomTimelineEvent(label: "Second", at: Date(timeIntervalSince1970: 200)))

        XCTAssertEqual(model.timelineEvents.map(\.id), [first.id, second.id])

        // Backdate the second event to before the first.
        model.updateTimelineEvent(second, timestamp: Date(timeIntervalSince1970: 50))

        XCTAssertEqual(model.timelineEvents.map(\.id), [second.id, first.id])
    }

    @MainActor
    func testDeleteTimelineEventRemovesItFromTheList() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let kept = try XCTUnwrap(model.addCustomTimelineEvent(label: "Kept", at: Date(timeIntervalSince1970: 100)))
        let removed = try XCTUnwrap(model.addCustomTimelineEvent(label: "Removed", at: Date(timeIntervalSince1970: 200)))

        model.deleteTimelineEvent(removed)

        XCTAssertEqual(model.timelineEvents.map(\.id), [kept.id])
    }

    @MainActor
    func testAddCustomTimelineEventIgnoresBlankLabels() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)

        XCTAssertNil(model.addCustomTimelineEvent())
        XCTAssertTrue(model.timelineEvents.isEmpty)

        XCTAssertNil(model.addCustomTimelineEvent(label: "   "))
        XCTAssertTrue(model.timelineEvents.isEmpty)

        let labeled = try XCTUnwrap(model.addCustomTimelineEvent(label: "Real event"))
        XCTAssertEqual(model.timelineEvents.map(\.id), [labeled.id])
    }

    @MainActor
    func testCloseAndReopenTaskPersistImmediately() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let closedAt = Date(timeIntervalSince1970: 900)

        model.closeTask(at: closedAt)

        XCTAssertEqual(try repository.task(id: task.id)?.closedAt, closedAt)
        XCTAssertNil(model.errorMessage)

        model.reopenTask()

        XCTAssertNil(try repository.task(id: task.id)?.closedAt)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor
    func testDeleteTaskRemovesTaskAndTimelineEvents() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        try repository.createTimelineEvent(for: task, label: "Callout from ECC")
        let model = TaskDetailViewModel(task: task, repository: repository)

        XCTAssertTrue(model.deleteTask())

        XCTAssertNil(try repository.task(id: task.id))
        XCTAssertTrue(try repository.timelineEvents(taskId: task.id).isEmpty)
        XCTAssertNil(model.errorMessage)
    }
}
