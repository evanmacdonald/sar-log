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
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Compact one-line digest of the entered vitals, skipping empty fields.
    private var summary: String {
        var parts: [String] = []
        if let hr = entry.heartRate { parts.append("HR \(hr)") }
        if let systolic = entry.systolicBloodPressure, let diastolic = entry.diastolicBloodPressure {
            parts.append("BP \(systolic)/\(diastolic)")
        }
        if let spo2 = entry.oxygenSaturation { parts.append("SpO₂ \(spo2)%") }
        if let rr = entry.respiratoryRate { parts.append("RR \(rr)") }
        if let total = entry.gcsTotal { parts.append("GCS \(total)") }
        if parts.isEmpty { return "No values yet — tap to fill in" }
        return parts.joined(separator: " · ")
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

/// Full vitals entry form. Every field auto-saves on each keystroke / selection
/// — "Done" only dismisses. All numeric input uses a number pad (no steppers,
/// per charter §4), and categorical fields are single-tap menu pickers.
///
/// When opened on a blank new entry and an earlier reading exists, each field
/// offers the previous value as a one-tap suggestion (plus an "apply all"
/// shortcut). Suggestions are opt-in: nothing is carried forward until the
/// scribe taps it, and an unconfirmed suggestion is never saved.
struct VitalsEntryEditor: View {
    @Bindable var model: TaskDetailViewModel
    let entry: VitalsEntry
    @Environment(\.dismiss) private var dismiss
    /// In-progress text for decimal fields, keyed by field title. Lets the user
    /// type intermediate states like "36." without the parsed value snapping
    /// the text back. The parsed value is still persisted on every keystroke.
    @State private var decimalDrafts: [String: String] = [:]
    /// Whether this entry was blank when the editor opened. Captured once so
    /// prefill is only offered on a freshly created entry, not when editing a
    /// reading recorded earlier — even after the scribe starts filling it in.
    @State private var startedBlank = false
    @State private var prefillConfigured = false

    /// The reading to copy from, resolved live so backdating this entry's
    /// timestamp re-picks the correct chronological predecessor.
    private var prefillSource: VitalsEntry? {
        model.previousVitalsEntry(before: entry)
    }

    var body: some View {
        NavigationStack {
            Form {
                if startedBlank, let source = prefillSource {
                    prefillBanner(source)
                }

                Section("Time") {
                    DatePicker(
                        "Time",
                        selection: timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel("Vitals time")
                }

                Section("Cardiorespiratory") {
                    intRow("Heart rate (bpm)", \.heartRate)
                    intRow("Systolic BP", \.systolicBloodPressure)
                    intRow("Diastolic BP", \.diastolicBloodPressure)
                    intRow("SpO₂ (%)", \.oxygenSaturation, in: 0...100)
                    intRow("Respiratory rate", \.respiratoryRate)
                    decimalRow("Temperature (°C)", "temperature", \.temperature)
                }

                Section("Glasgow Coma Scale") {
                    intRow("Eye (1–4)", \.gcsEye, in: VitalsRange.gcsEye)
                    intRow("Verbal (1–5)", \.gcsVerbal, in: VitalsRange.gcsVerbal)
                    intRow("Motor (1–6)", \.gcsMotor, in: VitalsRange.gcsMotor)
                    LabeledContent("Total", value: entry.gcsTotal.map { String($0) } ?? "—")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .accessibilityLabel("GCS total")
                        .accessibilityValue(entry.gcsTotal.map { String($0) } ?? "Incomplete")
                }

                Section("Pupils") {
                    decimalRow("Left size (mm)", "leftPupilSize", \.leftPupilSize)
                    optionRow("Left reactivity", \.leftPupilReactivity, options: VitalsFieldOptions.pupilReactivity)
                    decimalRow("Right size (mm)", "rightPupilSize", \.rightPupilSize)
                    optionRow("Right reactivity", \.rightPupilReactivity, options: VitalsFieldOptions.pupilReactivity)
                }

                Section("Other") {
                    intRow("Pain (0–10)", \.painScore, in: VitalsRange.pain)
                    optionRow("Capillary refill", \.capillaryRefill, options: VitalsFieldOptions.capillaryRefill)
                    optionRow("LOC / AVPU", \.levelOfConsciousness, options: VitalsFieldOptions.levelOfConsciousness)
                }

                Section("Skin") {
                    optionRow("Colour", \.skinColour, options: VitalsFieldOptions.skinColour)
                    optionRow("Temperature", \.skinTemperature, options: VitalsFieldOptions.skinTemperature)
                    optionRow("Moisture", \.skinMoisture, options: VitalsFieldOptions.skinMoisture)
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
            .task {
                if !prefillConfigured {
                    startedBlank = !entry.hasClinicalData
                    prefillConfigured = true
                }
            }
        }
    }

    // MARK: - Prefill

    private func prefillBanner(_ source: VitalsEntry) -> some View {
        Section {
            Text("Last reading at \(source.timestamp.formatted(date: .omitted, time: .shortened)). Tap a field's suggestion to copy it, or copy them all.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                model.applyPrefill(to: entry, from: source)
            } label: {
                Label("Use all previous values", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Use all previous values")
        } header: {
            Text("Prefill from previous")
        }
    }

    /// One-tap suggestion shown beneath an empty field when prefill is offered
    /// and the previous reading has a value for it.
    @ViewBuilder
    private func suggestion<Value: Equatable>(
        _ title: String,
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Value?>,
        format: (Value) -> String
    ) -> some View {
        if startedBlank,
           entry[keyPath: keyPath] == nil,
           let previous = prefillSource?[keyPath: keyPath] {
            Button {
                model.updateVitalsEntry(entry, set: keyPath, to: Optional(previous))
            } label: {
                Label("Use \(format(previous))", systemImage: "arrow.uturn.down")
                    .font(.footnote)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Use previous \(title): \(format(previous))")
        }
    }

    // MARK: - Field rows

    private func intRow(
        _ title: String,
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Int?>,
        in range: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            TextField(title, text: intField(keyPath, in: range))
                .keyboardType(.numberPad)
                .font(.body)
                .accessibilityLabel(title)
            suggestion(title, keyPath) { String($0) }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }

    private func decimalRow(
        _ title: String,
        _ key: String,
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Double?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            TextField(title, text: decimalField(key, keyPath))
                .keyboardType(.decimalPad)
                .font(.body)
                .accessibilityLabel(title)
            suggestion(title, keyPath) { String($0) }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }

    private func optionRow(
        _ title: String,
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, String?>,
        options: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker(title, selection: optionField(keyPath)) {
                Text("—").tag(String?.none)
                ForEach(options, id: \.self) { option in
                    Text(option).tag(String?.some(option))
                }
            }
            .frame(minHeight: 44)
            .accessibilityLabel(title)
            suggestion(title, keyPath) { $0 }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Bindings

    private var timestamp: Binding<Date> {
        Binding(
            get: { entry.timestamp },
            set: { model.updateVitalsEntryTimestamp(entry, timestamp: $0) }
        )
    }

    private func intField(
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Int?>,
        in range: ClosedRange<Int>? = nil
    ) -> Binding<String> {
        Binding(
            get: { entry[keyPath: keyPath].map { String($0) } ?? "" },
            set: { model.updateVitalsEntry(entry, set: keyPath, to: VitalsInput.boundedInt($0, in: range)) }
        )
    }

    private func decimalField(_ key: String, _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Double?>) -> Binding<String> {
        Binding(
            get: { decimalDrafts[key] ?? entry[keyPath: keyPath].map { String($0) } ?? "" },
            set: { newValue in
                decimalDrafts[key] = newValue
                model.updateVitalsEntry(entry, set: keyPath, to: VitalsInput.decimal(newValue))
            }
        )
    }

    private func optionField(_ keyPath: ReferenceWritableKeyPath<VitalsEntry, String?>) -> Binding<String?> {
        Binding(
            get: { entry[keyPath: keyPath] },
            set: { model.updateVitalsEntry(entry, set: keyPath, to: $0) }
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
