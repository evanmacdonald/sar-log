import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskDetailViewModel {
    private let repository: TaskRepository
    let task: SARTask

    init(task: SARTask, repository: TaskRepository) {
        self.task = task
        self.repository = repository
    }

    convenience init(task: SARTask, context: ModelContext) {
        self.init(task: task, repository: TaskRepository(context: context))
    }

    var mapsURL: URL? {
        CoordinateLocationParser.appleMapsURL(for: task.location)
    }

    func updateTaskNumber(_ value: String) {
        try? repository.update(task, taskNumber: value)
    }

    func updateSubjectName(_ value: String) {
        try? repository.update(task, subjectName: value)
    }

    func updateLocation(_ value: String) {
        try? repository.update(task, location: value)
    }

    func updateScribeName(_ value: String) {
        try? repository.update(task, scribeName: value)
    }

    func updateNotes(_ value: String) {
        try? repository.update(task, notes: value)
    }
}
