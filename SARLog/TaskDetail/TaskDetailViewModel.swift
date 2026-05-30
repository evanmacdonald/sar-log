import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskDetailViewModel {
    private let repository: TaskRepository
    let task: SARTask
    var timelineEvents: [TimelineEvent] = []
    var vitalsEntries: [VitalsEntry] = []
    var errorMessage: String?

    init(task: SARTask, repository: TaskRepository) {
        self.task = task
        self.repository = repository
        refreshLogEntries()
    }

    convenience init(task: SARTask, context: ModelContext) {
        self.init(task: task, repository: TaskRepository(context: context))
    }

    var predefinedTimelineEvents: [PredefinedTimelineEvent] {
        PredefinedTimelineEvent.all
    }

    func refreshTimeline() {
        refreshLogEntries()
    }

    func refreshLogEntries() {
        do {
            timelineEvents = try repository.timelineEvents(for: task)
            vitalsEntries = try repository.vitalsEntries(for: task)
            errorMessage = nil
        } catch {
            timelineEvents = []
            vitalsEntries = []
            errorMessage = "Log entries could not be loaded."
        }
    }

    func addPredefinedTimelineEvent(_ event: PredefinedTimelineEvent, at timestamp: Date = .now) {
        performMutation {
            try repository.createTimelineEvent(
                for: task,
                label: event.label,
                timestamp: timestamp,
                isCustom: false
            )
        }
    }

    @discardableResult
    func addCustomTimelineEvent(label: String = "", at timestamp: Date = .now) -> TimelineEvent? {
        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return performMutation {
            try repository.createTimelineEvent(
                for: task,
                label: label,
                timestamp: timestamp,
                isCustom: true
            )
        }
    }

    func updateTimelineEvent(_ event: TimelineEvent, label: String? = nil, timestamp: Date? = nil) {
        performMutation {
            try repository.updateTimelineEvent(event, label: label, timestamp: timestamp)
        }
    }

    func deleteTimelineEvent(_ event: TimelineEvent) {
        performMutation {
            try repository.deleteTimelineEvent(event)
        }
    }

    @discardableResult
    func addVitalsEntry(at timestamp: Date = .now) -> VitalsEntry? {
        performMutation {
            try repository.createVitalsEntry(for: task, timestamp: timestamp)
        }
    }

    func updateVitalsEntryTimestamp(_ entry: VitalsEntry, timestamp: Date) {
        performMutation {
            try repository.updateVitalsEntryTimestamp(entry, timestamp: timestamp)
        }
    }

    func updateVitalsEntryHeartRate(_ entry: VitalsEntry, heartRate: Int?) {
        performMutation {
            try repository.updateVitalsEntryHeartRate(entry, heartRate: heartRate)
        }
    }

    func updateVitalsEntry<Value>(
        _ entry: VitalsEntry,
        set keyPath: ReferenceWritableKeyPath<VitalsEntry, Value>,
        to value: Value
    ) {
        performMutation {
            try repository.updateVitalsEntry(entry, set: keyPath, to: value)
        }
    }

    /// The reading recorded immediately before `entry` (chronologically), or
    /// `nil` if it's the first. Drives the opt-in prefill suggestions.
    func previousVitalsEntry(before entry: VitalsEntry) -> VitalsEntry? {
        guard
            let index = vitalsEntries.firstIndex(where: { $0.id == entry.id }),
            index > 0
        else {
            return nil
        }
        return vitalsEntries[index - 1]
    }

    /// Carry the previous reading's values into `entry` for every field the
    /// scribe hasn't already filled. Explicit opt-in — never called
    /// automatically.
    func applyPrefill(to entry: VitalsEntry, from source: VitalsEntry) {
        performMutation {
            try repository.prefillVitalsEntry(entry, from: source)
        }
    }

    func updateTaskNumber(_ value: String) {
        updateTask {
            try repository.update(task, taskNumber: value)
        }
    }

    func updateSubjectName(_ value: String) {
        updateTask {
            try repository.update(task, subjectName: value)
        }
    }

    func updateLocation(_ value: String) {
        updateTask {
            try repository.update(task, location: value)
        }
    }

    func updateScribeName(_ value: String) {
        updateTask {
            try repository.update(task, scribeName: value)
        }
    }

    func updateNotes(_ value: String) {
        updateTask {
            try repository.update(task, notes: value)
        }
    }

    func closeTask(at closedAt: Date = .now) {
        updateTask {
            try repository.close(task, at: closedAt)
        }
    }

    func reopenTask() {
        updateTask {
            try repository.reopen(task)
        }
    }

    @discardableResult
    func deleteTask() -> Bool {
        do {
            try repository.delete(task)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Task could not be deleted. Try again before leaving this screen."
            return false
        }
    }

    @discardableResult
    private func performMutation<Result>(_ operation: () throws -> Result) -> Result? {
        do {
            let result = try operation()
            refreshLogEntries()
            errorMessage = nil
            return result
        } catch {
            refreshLogEntries()
            errorMessage = "Change could not be saved. Try again before leaving this screen."
            return nil
        }
    }

    private func updateTask(_ operation: () throws -> Void) {
        do {
            try operation()
            errorMessage = nil
        } catch {
            errorMessage = "Change could not be saved. Try again before leaving this screen."
        }
    }
}
