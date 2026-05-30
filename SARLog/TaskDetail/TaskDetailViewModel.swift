import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskDetailViewModel {
    private let repository: TaskRepository
    let task: SARTask
    var timelineEvents: [TimelineEvent] = []

    init(task: SARTask, repository: TaskRepository) {
        self.task = task
        self.repository = repository
        refreshTimeline()
    }

    convenience init(task: SARTask, context: ModelContext) {
        self.init(task: task, repository: TaskRepository(context: context))
    }

    var mapsURL: URL? {
        CoordinateLocationParser.appleMapsURL(for: task.location)
    }

    var predefinedTimelineEvents: [PredefinedTimelineEvent] {
        PredefinedTimelineEvent.all
    }

    func refreshTimeline() {
        timelineEvents = (try? repository.timelineEvents(for: task)) ?? []
    }

    func addPredefinedTimelineEvent(_ event: PredefinedTimelineEvent, at timestamp: Date = .now) {
        _ = try? repository.createTimelineEvent(
            for: task,
            label: event.label,
            timestamp: timestamp,
            isCustom: false
        )
        refreshTimeline()
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
