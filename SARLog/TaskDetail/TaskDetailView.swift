import SwiftUI

struct TaskDetailView: View {
    let task: SARTask
    @Environment(\.modelContext) private var modelContext
    @State private var model: TaskDetailViewModel?

    var body: some View {
        Group {
            if let model {
                TaskDetailContent(model: model)
            } else {
                ProgressView()
            }
        }
        .task {
            if model == nil {
                model = TaskDetailViewModel(task: task, context: modelContext)
            }
        }
    }
}

struct TaskDetailContent: View {
    @Bindable var model: TaskDetailViewModel
    @Environment(\.openURL) private var openURL
    @State private var editingEvent: TimelineEvent?
    @State private var pendingDraftEvent: TimelineEvent?
    private let eventButtonColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        List {
            Section("Task") {
                detailTextField("Task #", text: taskNumber)
                detailTextField("Subject", text: subjectName)
                detailTextField("Location", text: location)
                detailTextField("Scribe", text: scribeName)
            }
            Section("Notes") {
                TextField("Notes", text: notes, axis: .vertical)
                    .lineLimit(6...12)
                    .frame(minHeight: 144, alignment: .top)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Notes")
            }
            Section("Timeline") {
                if model.timelineEvents.isEmpty {
                    Text("No timeline events yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                } else {
                    ForEach(model.timelineEvents) { event in
                        Button {
                            editingEvent = event
                        } label: {
                            TimelineEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit event")
                    }
                }
            }
            Section("Status") {
                LabeledContent("Created", value: model.task.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("State", value: model.task.closedAt == nil ? "Active" : "Closed")
            }
        }
        .navigationTitle(TaskRowPresentation.title(taskNumber: model.task.taskNumber, subjectName: model.task.subjectName))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActionPanel
        }
        .sheet(item: $editingEvent, onDismiss: discardEmptyDraft) { event in
            TimelineEventEditor(model: model, event: event)
        }
    }

    private func discardEmptyDraft() {
        if let pendingDraftEvent {
            model.discardIfEmpty(pendingDraftEvent)
            self.pendingDraftEvent = nil
        }
    }

    private var bottomActionPanel: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: eventButtonColumns, spacing: 10) {
                ForEach(model.predefinedTimelineEvents) { event in
                    Button {
                        model.addPredefinedTimelineEvent(event)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: event.systemImage)
                                .font(.title3)
                            Text(event.label)
                                .font(.callout.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(event.label)
                }
            }

            Button {
                let draft = model.addCustomTimelineEvent()
                pendingDraftEvent = draft
                editingEvent = draft
            } label: {
                Label("Add custom event", systemImage: "plus.circle")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Add custom event")

            if let mapsURL = model.mapsURL {
                Button {
                    openURL(mapsURL)
                } label: {
                    Label("Open in Maps", systemImage: "map")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.bar)
    }

    private var taskNumber: Binding<String> {
        Binding(
            get: { model.task.taskNumber },
            set: { model.updateTaskNumber($0) }
        )
    }

    private var subjectName: Binding<String> {
        Binding(
            get: { model.task.subjectName },
            set: { model.updateSubjectName($0) }
        )
    }

    private var location: Binding<String> {
        Binding(
            get: { model.task.location },
            set: { model.updateLocation($0) }
        )
    }

    private var scribeName: Binding<String> {
        Binding(
            get: { model.task.scribeName },
            set: { model.updateScribeName($0) }
        )
    }

    private var notes: Binding<String> {
        Binding(
            get: { model.task.notes },
            set: { model.updateNotes($0) }
        )
    }

    private func detailTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .font(.body)
                .textInputAutocapitalization(.words)
                .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.label)
                .font(.headline)
            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Edit (or backdate) a single timeline event. Every change auto-saves
/// immediately — "Done" only dismisses, there is no Save button.
struct TimelineEventEditor: View {
    @Bindable var model: TaskDetailViewModel
    let event: TimelineEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Label", text: label, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Event label")
                }
                Section("Time") {
                    DatePicker(
                        "Time",
                        selection: timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel("Event time")
                }
                Section {
                    Button(role: .destructive) {
                        model.deleteTimelineEvent(event)
                        dismiss()
                    } label: {
                        Label("Delete event", systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .accessibilityLabel("Delete event")
                }
            }
            .navigationTitle("Edit event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var label: Binding<String> {
        Binding(
            get: { event.label },
            set: { model.updateTimelineEvent(event, label: $0) }
        )
    }

    private var timestamp: Binding<Date> {
        Binding(
            get: { event.timestamp },
            set: { model.updateTimelineEvent(event, timestamp: $0) }
        )
    }
}
