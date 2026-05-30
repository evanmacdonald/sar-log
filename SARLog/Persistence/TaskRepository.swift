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
        for event in try timelineEvents(for: task) {
            context.delete(event)
        }
        context.delete(task)
        try context.save()
    }

    @discardableResult
    func createTimelineEvent(
        id: UUID = UUID(),
        taskId: UUID,
        label: String,
        timestamp: Date = .now,
        isCustom: Bool = false
    ) throws -> TimelineEvent {
        let event = TimelineEvent(
            id: id,
            taskId: taskId,
            label: label,
            timestamp: timestamp,
            isCustom: isCustom
        )

        context.insert(event)
        try context.save()
        return event
    }

    @discardableResult
    func createTimelineEvent(
        for task: SARTask,
        id: UUID = UUID(),
        label: String,
        timestamp: Date = .now,
        isCustom: Bool = false
    ) throws -> TimelineEvent {
        try createTimelineEvent(
            id: id,
            taskId: task.id,
            label: label,
            timestamp: timestamp,
            isCustom: isCustom
        )
    }

    func updateTimelineEvent(
        _ event: TimelineEvent,
        label: String? = nil,
        timestamp: Date? = nil
    ) throws {
        if let label {
            event.label = label
        }
        if let timestamp {
            event.timestamp = timestamp
        }

        try context.save()
    }

    func deleteTimelineEvent(_ event: TimelineEvent) throws {
        context.delete(event)
        try context.save()
    }

    func timelineEvents(for task: SARTask) throws -> [TimelineEvent] {
        try timelineEvents(taskId: task.id)
    }

    func timelineEvents(taskId: UUID) throws -> [TimelineEvent] {
        var descriptor = FetchDescriptor<TimelineEvent>(
            predicate: #Predicate { $0.taskId == taskId }
        )
        descriptor.includePendingChanges = true
        return sortTimelineEvents(try context.fetch(descriptor))
    }

    private func sortTimelineEvents(_ events: [TimelineEvent]) -> [TimelineEvent] {
        events.sorted { first, second in
            if first.timestamp != second.timestamp {
                return first.timestamp < second.timestamp
            }
            if first.label != second.label {
                return first.label < second.label
            }
            return first.id.uuidString < second.id.uuidString
        }
    }
}
