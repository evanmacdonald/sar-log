import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskListViewModel {
    private let repository: TaskRepository

    private(set) var activeTasks: [SARTask] = []
    private(set) var closedTasks: [SARTask] = []

    init(repository: TaskRepository) {
        self.repository = repository
        refresh()
    }

    convenience init(context: ModelContext) {
        self.init(repository: TaskRepository(context: context))
    }

    var isEmpty: Bool {
        activeTasks.isEmpty && closedTasks.isEmpty
    }

    func refresh() {
        activeTasks = (try? repository.activeTasks()) ?? []
        closedTasks = (try? repository.closedTasks()) ?? []
    }

    @discardableResult
    func createTask() -> SARTask? {
        let task = try? repository.createTask()
        refresh()
        return task
    }

    func close(_ task: SARTask) {
        try? repository.close(task)
        refresh()
    }

    func reopen(_ task: SARTask) {
        try? repository.reopen(task)
        refresh()
    }

    func delete(_ task: SARTask) {
        try? repository.delete(task)
        refresh()
    }
}
