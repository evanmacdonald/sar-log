import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskListViewModel {
    private let repository: TaskRepository

    private(set) var activeTasks: [SARTask] = []
    private(set) var closedTasks: [SARTask] = []
    var pendingVitalsDraft: VitalsDraftRecovery?
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
            pendingVitalsDraft = try recoverableVitalsDraft()
            errorMessage = nil
        } catch {
            activeTasks = []
            closedTasks = []
            pendingVitalsDraft = nil
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

    func task(id: UUID) -> SARTask? {
        do {
            return try repository.task(id: id)
        } catch {
            errorMessage = "Task could not be restored."
            return nil
        }
    }

    func resumePendingVitalsDraft() -> VitalsDraftRecovery? {
        let draft = pendingVitalsDraft
        pendingVitalsDraft = nil
        return draft
    }

    func discardPendingVitalsDraft() {
        guard let draft = pendingVitalsDraft else { return }
        performMutation {
            try repository.deleteVitalsEntry(draft.entry)
        }
    }

    private func recoverableVitalsDraft() throws -> VitalsDraftRecovery? {
        let drafts = try repository.draftVitalsEntries().reversed()
        for entry in drafts {
            if let task = try repository.task(id: entry.taskId) {
                return VitalsDraftRecovery(task: task, entry: entry)
            }
            try repository.deleteVitalsEntry(entry)
        }
        return nil
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

struct VitalsDraftRecovery: Identifiable {
    var id: UUID { entry.id }
    let task: SARTask
    let entry: VitalsEntry

    var taskTitle: String {
        TaskRowPresentation.title(taskNumber: task.taskNumber, subjectName: task.subjectName)
    }
}

enum TaskSceneRestoration {
    static func taskID(from storageValue: String) -> UUID? {
        UUID(uuidString: storageValue)
    }

    static func storageValue(for task: SARTask?) -> String {
        task?.id.uuidString ?? ""
    }
}
