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

    /// A closed task is read-only. All edit/add mutations are blocked until the
    /// task is reopened; only close/reopen and delete remain available.
    var isClosed: Bool {
        task.closedAt != nil
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

    func timelineEvent(id: UUID) -> TimelineEvent? {
        do {
            return try repository.timelineEvent(id: id)
        } catch {
            errorMessage = "Timeline event could not be loaded."
            return nil
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
            try repository.createVitalsEntry(for: task, timestamp: timestamp, isDraft: true)
        }
    }

    func vitalsEntry(id: UUID) -> VitalsEntry? {
        do {
            return try repository.vitalsEntry(id: id)
        } catch {
            errorMessage = "Vitals entry could not be loaded."
            return nil
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

    /// The most recent finished reading before `entry` (chronologically) that
    /// actually has clinical data, or `nil` if there isn't one. Blank entries
    /// are skipped so an accidental empty row doesn't become a do-nothing
    /// prefill source, and drafts are skipped so an in-progress reading doesn't
    /// become a prefill source before the scribe taps Done.
    func previousVitalsEntry(before entry: VitalsEntry) -> VitalsEntry? {
        guard let index = vitalsEntries.firstIndex(where: { $0.id == entry.id }) else {
            return nil
        }
        return vitalsEntries[..<index].last { !$0.isDraft && $0.hasClinicalData }
    }

    @discardableResult
    func finishVitalsEntry(_ entry: VitalsEntry) -> Bool {
        guard !isClosed else { return false }
        do {
            try repository.finalizeVitalsEntry(entry)
            refreshLogEntries()
            errorMessage = nil
            return true
        } catch {
            refreshLogEntries()
            errorMessage = "Vitals entry could not be saved. Try again before leaving this screen."
            return false
        }
    }

    @discardableResult
    func discardVitalsEntry(_ entry: VitalsEntry) -> Bool {
        guard !isClosed else { return false }
        do {
            try repository.deleteVitalsEntry(entry)
            refreshLogEntries()
            errorMessage = nil
            return true
        } catch {
            refreshLogEntries()
            errorMessage = "Vitals entry could not be discarded. Try again before leaving this screen."
            return false
        }
    }

    func updateTaskNumber(_ value: String) {
        updateEditableField {
            try repository.update(task, taskNumber: value)
        }
    }

    func updateSubjectName(_ value: String) {
        updateEditableField {
            try repository.update(task, subjectName: value)
        }
    }

    func updateLocation(_ value: String) {
        updateEditableField {
            try repository.update(task, location: value)
        }
    }

    func updateScribeName(_ value: String) {
        updateEditableField {
            try repository.update(task, scribeName: value)
        }
    }

    func updateNotes(_ value: String) {
        updateEditableField {
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

    func exportPDF(generatedAt: Date = .now) -> URL? {
        do {
            let events = try repository.timelineEvents(for: task)
            let entries = try repository.vitalsEntries(for: task)
            let report = SARLogPDFReportBuilder.makeReport(
                task: task,
                timelineEvents: events,
                vitalsEntries: entries,
                generatedAt: generatedAt
            )
            let url = try SARLogPDFFileExporter.writeTemporaryPDF(report: report)
            errorMessage = nil
            return url
        } catch {
            errorMessage = "PDF could not be created. Try again before sharing this task."
            return nil
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
        guard !isClosed else { return nil }
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

    /// Field edits that must be blocked on a closed task. Close/reopen use
    /// `updateTask` directly so they stay available regardless of state.
    private func updateEditableField(_ operation: () throws -> Void) {
        guard !isClosed else { return }
        updateTask(operation)
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
