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
}
