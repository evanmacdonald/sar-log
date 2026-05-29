import Foundation
import SwiftData
import XCTest
@testable import SARLog

final class TaskListViewModelTests: XCTestCase {
    @MainActor
    func testStartsEmpty() throws {
        let store = try makeStore()
        XCTAssertTrue(store.model.isEmpty)
        XCTAssertTrue(store.model.activeTasks.isEmpty)
        XCTAssertTrue(store.model.closedTasks.isEmpty)
    }

    @MainActor
    func testCreateTaskAppearsAsActive() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.model.createTask())

        XCTAssertFalse(store.model.isEmpty)
        XCTAssertEqual(store.model.activeTasks.map(\.id), [task.id])
        XCTAssertTrue(store.model.closedTasks.isEmpty)
    }

    @MainActor
    func testCloseMovesTaskToClosedSection() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.model.createTask())

        store.model.close(task)

        XCTAssertTrue(store.model.activeTasks.isEmpty)
        XCTAssertEqual(store.model.closedTasks.map(\.id), [task.id])
        XCTAssertNotNil(store.model.closedTasks.first?.closedAt)
    }

    @MainActor
    func testReopenMovesTaskBackToActive() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.model.createTask())
        store.model.close(task)

        store.model.reopen(task)

        XCTAssertEqual(store.model.activeTasks.map(\.id), [task.id])
        XCTAssertTrue(store.model.closedTasks.isEmpty)
    }

    @MainActor
    func testDeleteRemovesTask() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.model.createTask())

        store.model.delete(task)

        XCTAssertTrue(store.model.isEmpty)
    }

    @MainActor
    func testActiveSortedNewestFirstAndClosedSeparated() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let oldest = try repository.createTask(createdAt: Date(timeIntervalSince1970: 100))
        let newest = try repository.createTask(createdAt: Date(timeIntervalSince1970: 300))
        let closed = try repository.createTask(
            createdAt: Date(timeIntervalSince1970: 200),
            closedAt: Date(timeIntervalSince1970: 400)
        )

        let model = TaskListViewModel(repository: repository)

        XCTAssertEqual(model.activeTasks.map(\.id), [newest.id, oldest.id])
        XCTAssertEqual(model.closedTasks.map(\.id), [closed.id])
    }

    @MainActor
    private func makeStore() throws -> ModelStore {
        let container = try SARLogModelContainer.inMemory()
        return ModelStore(
            container: container,
            model: TaskListViewModel(context: container.mainContext)
        )
    }
}

@MainActor
private struct ModelStore {
    let container: ModelContainer
    let model: TaskListViewModel
}
