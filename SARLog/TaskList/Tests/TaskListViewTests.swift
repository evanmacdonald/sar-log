import SwiftData
import SwiftUI
import XCTest
@testable import SARLog

final class TaskListViewTests: XCTestCase {
    @MainActor
    func testHostViewBuildsWhileModelLoads() {
        _ = TaskListView().body
    }

    @MainActor
    func testContentBuildsEmptyState() throws {
        let model = try makeModel()
        _ = TaskListContent(model: model).body
    }

    @MainActor
    func testContentBuildsPopulatedListAndRows() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        try repository.createTask(taskNumber: "2026-001", subjectName: "Active subject")
        try repository.createTask(
            subjectName: "Closed subject",
            closedAt: Date(timeIntervalSince1970: 10)
        )
        let model = TaskListViewModel(repository: repository)

        _ = TaskListContent(model: model).body
        _ = TaskRow(task: try XCTUnwrap(model.activeTasks.first)).body
        _ = TaskRow(task: try XCTUnwrap(model.closedTasks.first)).body
    }

    @MainActor
    func testDetailViewBuildsForActiveAndClosedTasks() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let active = try repository.createTask(taskNumber: "2026-001")
        let closed = try repository.createTask(
            subjectName: "Subject",
            closedAt: Date(timeIntervalSince1970: 10)
        )

        _ = TaskDetailView(task: active).body
        _ = TaskDetailView(task: closed).body
    }

    @MainActor
    private func makeModel() throws -> TaskListViewModel {
        let container = try SARLogModelContainer.inMemory()
        return TaskListViewModel(context: container.mainContext)
    }
}
