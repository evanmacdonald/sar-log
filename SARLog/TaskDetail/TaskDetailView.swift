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
    @Environment(\.dismiss) private var dismiss
    @State private var editingEvent: TimelineEvent?
    @State private var editingVitalsEntry: VitalsEntry?
    @State private var isAddingCustomEvent = false
    @State private var isConfirmingDelete = false
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
            Section("Vitals") {
                if model.vitalsEntries.isEmpty {
                    Text("No vitals yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                } else {
                    ForEach(model.vitalsEntries) { entry in
                        Button {
                            editingVitalsEntry = entry
                        } label: {
                            VitalsEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit vitals")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                taskActionsMenu
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionPanel
        }
        .sheet(item: $editingEvent) { event in
            TimelineEventEditor(model: model, event: event)
        }
        .sheet(isPresented: $isAddingCustomEvent) {
            NewTimelineEventEditor(model: model)
        }
        .sheet(item: $editingVitalsEntry) { entry in
            VitalsEntryEditor(model: model, entry: entry)
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete task", role: .destructive) {
                if model.deleteTask() {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the task and its log. This can't be undone.")
        }
        .alert("Save problem", isPresented: errorBinding) {
            Button("OK") {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "Try again before leaving this screen.")
        }
    }

    private var taskActionsMenu: some View {
        Menu {
            Button {
                toggleTaskClosedState()
            } label: {
                Label(
                    model.task.closedAt == nil ? "Close task" : "Reopen task",
                    systemImage: model.task.closedAt == nil ? "checkmark.circle" : "arrow.uturn.backward.circle"
                )
            }

            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("Delete task", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
        }
        .accessibilityLabel("Task actions")
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

            HStack(spacing: 10) {
                Button {
                    isAddingCustomEvent = true
                } label: {
                    Label("Custom event", systemImage: "plus.circle")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add custom event")

                Button {
                    if let entry = model.addVitalsEntry() {
                        editingVitalsEntry = entry
                    }
                } label: {
                    Label("Add vitals", systemImage: "waveform.path.ecg")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add vitals")
            }
        }
        .padding()
        .background(.bar)
    }

    private func toggleTaskClosedState() {
        if model.task.closedAt == nil {
            model.closeTask()
        } else {
            model.reopenTask()
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    model.errorMessage = nil
                }
            }
        )
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

struct VitalsEntryRow: View {
    let entry: VitalsEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            Spacer()
            LabeledContent("HR", value: entry.heartRate.map { String($0) } ?? "--")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Creates a custom event only after the user enters non-empty text. This keeps
/// crashes or backgrounding from leaving a blank event in the timeline.
struct NewTimelineEventEditor: View {
    @Bindable var model: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var timestamp = Date.now
    @State private var event: TimelineEvent?

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Label", text: labelBinding, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Event label")
                }
                Section("Time") {
                    DatePicker(
                        "Time",
                        selection: timestampBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel("Event time")
                }
            }
            .navigationTitle("Add event")
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

    private var labelBinding: Binding<String> {
        Binding(
            get: { label },
            set: { newValue in
                label = newValue
                persistDraft()
            }
        )
    }

    private var timestampBinding: Binding<Date> {
        Binding(
            get: { timestamp },
            set: { newValue in
                timestamp = newValue
                if let event {
                    model.updateTimelineEvent(event, timestamp: newValue)
                }
            }
        )
    }

    private func persistDraft() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLabel.isEmpty {
            if let event {
                model.deleteTimelineEvent(event)
                self.event = nil
            }
            return
        }

        if let event {
            model.updateTimelineEvent(event, label: label)
        } else {
            event = model.addCustomTimelineEvent(label: label, at: timestamp)
        }
    }
}

struct VitalsEntryEditor: View {
    @Bindable var model: TaskDetailViewModel
    let entry: VitalsEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker(
                        "Time",
                        selection: timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel("Vitals time")
                }
                Section("Vitals") {
                    TextField("HR", text: heartRate)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Heart rate")
                }
            }
            .navigationTitle("Vitals")
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

    private var timestamp: Binding<Date> {
        Binding(
            get: { entry.timestamp },
            set: { model.updateVitalsEntryTimestamp(entry, timestamp: $0) }
        )
    }

    private var heartRate: Binding<String> {
        Binding(
            get: { entry.heartRate.map { String($0) } ?? "" },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                model.updateVitalsEntryHeartRate(entry, heartRate: digits.isEmpty ? nil : Int(digits))
            }
        )
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
