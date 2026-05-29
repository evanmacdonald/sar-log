import Foundation
import SwiftData
import XCTest
@testable import SARLog

final class TaskRepositoryTests: XCTestCase {
    @MainActor
    func testCreateAndFetchTask() throws {
        let store = try makeRepository()
        let repository = store.repository
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_800)

        try repository.createTask(
            id: id,
            taskNumber: "2026-001",
            subjectName: "Taylor Example",
            location: "Trailhead",
            scribeName: "Evan",
            notes: "Initial notes",
            createdAt: createdAt
        )

        let fetched = try XCTUnwrap(repository.task(id: id))
        XCTAssertEqual(fetched.taskNumber, "2026-001")
        XCTAssertEqual(fetched.subjectName, "Taylor Example")
        XCTAssertEqual(fetched.location, "Trailhead")
        XCTAssertEqual(fetched.scribeName, "Evan")
        XCTAssertEqual(fetched.notes, "Initial notes")
        XCTAssertEqual(fetched.createdAt, createdAt)
        XCTAssertNil(fetched.closedAt)
    }

    @MainActor
    func testUpdateAndDeleteTask() throws {
        let store = try makeRepository()
        let repository = store.repository
        let task = try repository.createTask(subjectName: "Original")

        try repository.update(
            task,
            taskNumber: "A-1",
            subjectName: "Updated",
            location: "49.123, -123.456",
            scribeName: "Scribe",
            notes: "Updated notes"
        )

        let updated = try XCTUnwrap(repository.task(id: task.id))
        XCTAssertEqual(updated.taskNumber, "A-1")
        XCTAssertEqual(updated.subjectName, "Updated")
        XCTAssertEqual(updated.location, "49.123, -123.456")
        XCTAssertEqual(updated.scribeName, "Scribe")
        XCTAssertEqual(updated.notes, "Updated notes")

        try repository.delete(updated)
        XCTAssertNil(try repository.task(id: task.id))
    }

    @MainActor
    func testActiveAndClosedQueriesRespectClosedAtTransitions() throws {
        let store = try makeRepository()
        let repository = store.repository
        let task = try repository.createTask(subjectName: "Active")

        XCTAssertEqual(try repository.activeTasks().map(\.id), [task.id])
        XCTAssertTrue(try repository.closedTasks().isEmpty)

        let closedAt = Date(timeIntervalSince1970: 2_200)
        try repository.close(task, at: closedAt)

        XCTAssertTrue(try repository.activeTasks().isEmpty)
        let closedTask = try XCTUnwrap(repository.closedTasks().first)
        XCTAssertEqual(closedTask.id, task.id)
        XCTAssertEqual(closedTask.closedAt, closedAt)

        try repository.reopen(closedTask)

        XCTAssertEqual(try repository.activeTasks().map(\.id), [task.id])
        XCTAssertTrue(try repository.closedTasks().isEmpty)
    }

    @MainActor
    func testTaskQueriesReturnNewestCreatedFirst() throws {
        let store = try makeRepository()
        let repository = store.repository
        let oldest = try repository.createTask(
            subjectName: "Oldest",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newest = try repository.createTask(
            subjectName: "Newest",
            createdAt: Date(timeIntervalSince1970: 300)
        )
        let middleClosed = try repository.createTask(
            subjectName: "Middle closed",
            createdAt: Date(timeIntervalSince1970: 200),
            closedAt: Date(timeIntervalSince1970: 400)
        )

        XCTAssertEqual(try repository.tasks().map(\.id), [newest.id, middleClosed.id, oldest.id])
        XCTAssertEqual(try repository.activeTasks().map(\.id), [newest.id, oldest.id])
        XCTAssertEqual(try repository.closedTasks().map(\.id), [middleClosed.id])
    }

    @MainActor
    func testPersistentStoreSurvivesContainerRecreation() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SARLog-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let storeURL = storeDirectory.appendingPathComponent("SARLog.store")
        let taskID = UUID()

        var firstContainer: ModelContainer? = try SARLogModelContainer.persistent(at: storeURL)
        var firstRepository: TaskRepository? = TaskRepository(context: try XCTUnwrap(firstContainer).mainContext)
        try firstRepository?.createTask(
            id: taskID,
            taskNumber: "Persisted",
            subjectName: "Subject",
            createdAt: Date(timeIntervalSince1970: 500)
        )

        firstRepository = nil
        firstContainer = nil

        let secondContainer = try SARLogModelContainer.persistent(at: storeURL)
        let secondRepository = TaskRepository(context: secondContainer.mainContext)
        let fetched = try XCTUnwrap(secondRepository.task(id: taskID))

        XCTAssertEqual(fetched.taskNumber, "Persisted")
        XCTAssertEqual(fetched.subjectName, "Subject")
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
