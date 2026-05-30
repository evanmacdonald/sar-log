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

    @discardableResult
    func addCustomTimelineEvent(label: String = "", at timestamp: Date = .now) -> TimelineEvent? {
        let event = try? repository.createTimelineEvent(
            for: task,
            label: label,
            timestamp: timestamp,
            isCustom: true
        )
        refreshTimeline()
        return event
    }

    func updateTimelineEvent(_ event: TimelineEvent, label: String? = nil, timestamp: Date? = nil) {
        try? repository.updateTimelineEvent(event, label: label, timestamp: timestamp)
        refreshTimeline()
    }

    func deleteTimelineEvent(_ event: TimelineEvent) {
        try? repository.deleteTimelineEvent(event)
        refreshTimeline()
    }

    /// Removes an in-progress custom event whose label was never filled in,
    /// so dismissing the editor without typing leaves no empty row behind.
    func discardIfEmpty(_ event: TimelineEvent) {
        if event.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deleteTimelineEvent(event)
        }
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
