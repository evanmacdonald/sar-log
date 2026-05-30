import SwiftUI

struct TaskDetailView: View {
    let task: SARTask

    var body: some View {
        List {
            Section("Task") {
                LabeledContent("Task #", value: displayValue(task.taskNumber))
                LabeledContent("Subject", value: displayValue(task.subjectName))
                LabeledContent("Location", value: displayValue(task.location))
                LabeledContent("Scribe", value: displayValue(task.scribeName))
            }
            Section("Status") {
                LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("State", value: task.closedAt == nil ? "Active" : "Closed")
            }
        }
        .navigationTitle(TaskRowPresentation.title(taskNumber: task.taskNumber, subjectName: task.subjectName))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }
}
