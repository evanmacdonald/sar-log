import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskListViewModel {
    private let repository: TaskRepository

    private(set) var activeTasks: [SARTask] = []
    private(set) var closedTasks: [SARTask] = []
    var errorMessage: String?

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
        do {
            activeTasks = try repository.activeTasks()
            closedTasks = try repository.closedTasks()
            errorMessage = nil
        } catch {
            activeTasks = []
            closedTasks = []
            errorMessage = "Task list could not be loaded."
        }
    }

    @discardableResult
    func createTask() -> SARTask? {
        performMutation {
            try repository.createTask()
        }
    }

    func close(_ task: SARTask) {
        performMutation {
            try repository.close(task)
        }
    }

    func reopen(_ task: SARTask) {
        performMutation {
            try repository.reopen(task)
        }
    }

    func delete(_ task: SARTask) {
        performMutation {
            try repository.delete(task)
        }
    }

    @discardableResult
    private func performMutation<Result>(_ operation: () throws -> Result) -> Result? {
        do {
            let result = try operation()
            refresh()
            errorMessage = nil
            return result
        } catch {
            refresh()
            errorMessage = "Change could not be saved. Try again before leaving this screen."
            return nil
        }
    }
}
