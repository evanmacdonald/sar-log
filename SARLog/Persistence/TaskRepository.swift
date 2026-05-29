import Foundation
import SwiftData

@MainActor
struct TaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func createTask(
        id: UUID = UUID(),
        taskNumber: String = "",
        subjectName: String = "",
        location: String = "",
        scribeName: String = "",
        notes: String = "",
        createdAt: Date = .now,
        closedAt: Date? = nil
    ) throws -> SARTask {
        let task = SARTask(
            id: id,
            taskNumber: taskNumber,
            subjectName: subjectName,
            location: location,
            scribeName: scribeName,
            notes: notes,
            createdAt: createdAt,
            closedAt: closedAt
        )

        context.insert(task)
        try context.save()
        return task
    }

    func task(id: UUID) throws -> SARTask? {
        let descriptor = FetchDescriptor<SARTask>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func tasks() throws -> [SARTask] {
        var descriptor = FetchDescriptor<SARTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    func activeTasks() throws -> [SARTask] {
        let descriptor = FetchDescriptor<SARTask>(
            predicate: #Predicate { $0.closedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func closedTasks() throws -> [SARTask] {
        let descriptor = FetchDescriptor<SARTask>(
            predicate: #Predicate { $0.closedAt != nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func update(
        _ task: SARTask,
        taskNumber: String? = nil,
        subjectName: String? = nil,
        location: String? = nil,
        scribeName: String? = nil,
        notes: String? = nil
    ) throws {
        if let taskNumber {
            task.taskNumber = taskNumber
        }
        if let subjectName {
            task.subjectName = subjectName
        }
        if let location {
            task.location = location
        }
        if let scribeName {
            task.scribeName = scribeName
        }
        if let notes {
            task.notes = notes
        }

        try context.save()
    }

    func close(_ task: SARTask, at closedAt: Date = .now) throws {
        task.closedAt = closedAt
        try context.save()
    }

    func reopen(_ task: SARTask) throws {
        task.closedAt = nil
        try context.save()
    }

    func delete(_ task: SARTask) throws {
        context.delete(task)
        try context.save()
    }
}
