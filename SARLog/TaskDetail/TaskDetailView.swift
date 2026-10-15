import SwiftUI

struct TaskDetailView: View {
    let task: SARTask
    var initialVitalsEntryID: UUID?
    var autofocusTaskNumber: Bool = false
    var onInitialVitalsEntryPresented: () -> Void = {}
    @Environment(\.modelContext) private var modelContext
    @State private var model: TaskDetailViewModel?

    var body: some View {
        Group {
            if let model {
                TaskDetailContent(
                    model: model,
                    initialVitalsEntryID: initialVitalsEntryID,
                    autofocusTaskNumber: autofocusTaskNumber,
                    onInitialVitalsEntryPresented: onInitialVitalsEntryPresented
                )
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
    var initialVitalsEntryID: UUID?
    var autofocusTaskNumber: Bool = false
    var onInitialVitalsEntryPresented: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @SceneStorage("TaskDetail.focusedField") private var focusedFieldRawValue = ""
    @SceneStorage("TaskDetail.editingEventID") private var editingEventIDString = ""
    @SceneStorage("TaskDetail.editingVitalsEntryID") private var editingVitalsEntryIDString = ""
    @SceneStorage("TaskDetail.isAddingCustomEvent") private var isAddingCustomEventStored = false
    @SceneStorage("TaskDetail.customEventID") private var customEventIDString = ""
    @SceneStorage("TaskDetail.quickEntryCollapsed") private var isQuickEntryCollapsed = false
    @FocusState private var focusedField: TaskDetailFocusField?
    @State private var editingEvent: TimelineEvent?
    @State private var editingVitalsEntry: VitalsEntry?
    @State private var isAddingCustomEvent = false
    @State private var isConfirmingDelete = false
    @State private var pdfShareItem: PDFShareItem?
    @State private var didPresentInitialVitalsEntry = false
    @State private var didRestoreEditor = false
    @State private var didAutofocusTaskNumber = false
    private let eventButtonColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        List {
            Section("Task") {
                detailTextField("Task #", text: taskNumber, field: .taskNumber)
                detailTextField("Subject", text: subjectName, field: .subjectName)
                detailTextField("Location", text: location, field: .location)
                detailTextField("Scribe", text: scribeName, field: .scribeName)
            }
            Section("Notes") {
                TextField("Notes", text: notes, axis: .vertical)
                    .lineLimit(6...12)
                    .frame(minHeight: 144, alignment: .top)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .notes)
                    .disabled(model.isClosed)
                    .accessibilityLabel("Notes")
            }
            Section("Timeline") {
                if model.timelineEvents.isEmpty {
                    Text("No timeline events yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                } else {
                    ForEach(model.timelineEvents) { event in
                        if model.isClosed {
                            TimelineEventRow(event: event)
                        } else {
                            Button {
                                editingEventSheet.wrappedValue = event
                            } label: {
                                TimelineEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Edit event")
                        }
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
                        if model.isClosed {
                            VitalsEntryRow(entry: entry)
                        } else {
                            Button {
                                editingVitalsEntrySheet.wrappedValue = entry
                            } label: {
                                VitalsEntryRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Edit vitals")
                        }
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
        .onAppear {
            presentInitialVitalsEntryIfNeeded()
            restoreFocusedFieldIfNeeded()
            restoreActiveEditorIfNeeded()
            focusTaskNumberIfNewTask()
        }
        .onChange(of: initialVitalsEntryID) { _, _ in
            didPresentInitialVitalsEntry = false
            presentInitialVitalsEntryIfNeeded()
        }
        .onChange(of: focusedField) { _, newValue in
            focusedFieldRawValue = TaskDetailFocusField.storageValue(for: newValue)
        }
        .sheet(item: editingEventSheet) { event in
            TimelineEventEditor(model: model, event: event)
        }
        .sheet(isPresented: customEventSheet) {
            NewTimelineEventEditor(
                model: model,
                initialEventID: TaskDetailSceneRestoration.id(from: customEventIDString)
            ) { event in
                customEventIDString = TaskDetailSceneRestoration.storageValue(for: event?.id)
            }
        }
        .sheet(item: editingVitalsEntrySheet) { entry in
            VitalsEntryEditor(model: model, entry: entry)
        }
        .sheet(item: $pdfShareItem) { item in
            PDFShareSheet(url: item.url)
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
                if let url = model.exportPDF() {
                    pdfShareItem = PDFShareItem(url: url)
                }
            } label: {
                Label("Export PDF", systemImage: "square.and.arrow.up")
            }

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

    /// Bottom panel. While a field is focused the keyboard covers the quick
    /// buttons anyway, so collapse them to a single large "Hide keyboard" bar:
    /// it sits in the thumb zone right above the keyboard, dismisses in one tap,
    /// and frees vertical space so the field being typed in stays visible.
    private var bottomActionPanel: some View {
        Group {
            if model.isClosed {
                closedTaskBar
                    .padding()
            } else if focusedField != nil {
                keyboardDismissBar
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            } else if isQuickEntryCollapsed {
                quickEntryToggle(collapsed: true)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 10) {
                    quickEntryToggle(collapsed: false)
                    quickActionButtons
                }
                .padding()
            }
        }
        .background(.bar)
        .animation(.easeInOut(duration: 0.2), value: focusedField)
        .animation(.easeInOut(duration: 0.2), value: isQuickEntryCollapsed)
        .animation(.easeInOut(duration: 0.2), value: model.isClosed)
    }

    /// Shown instead of the quick-entry panel once a task is closed. The task
    /// is read-only, so the only action offered is reopening it to edit again.
    private var closedTaskBar: some View {
        VStack(spacing: 8) {
            Label("This task is closed — read only", systemImage: "lock.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                model.reopenTask()
            } label: {
                Label("Reopen to edit", systemImage: "arrow.uturn.backward.circle")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Reopen task to edit")
        }
    }

    /// Slim handle to collapse the quick-entry panel (for a full-page view of
    /// the task) or re-expand it. Collapsed state persists via scene storage
    /// so it survives backgrounding and relaunch.
    private func quickEntryToggle(collapsed: Bool) -> some View {
        Button {
            isQuickEntryCollapsed.toggle()
        } label: {
            Label(
                collapsed ? "Quick entry" : "Minimize",
                systemImage: collapsed ? "chevron.up" : "chevron.down"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel(collapsed ? "Show quick entry buttons" : "Minimize quick entry buttons")
    }

    private var keyboardDismissBar: some View {
        Button {
            focusedField = nil
        } label: {
            Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Hide keyboard")
        .accessibilityHint("Dismisses the keyboard and shows the quick event buttons")
    }

    private var quickActionButtons: some View {
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
                    customEventIDString = ""
                    customEventSheet.wrappedValue = true
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
                        editingVitalsEntrySheet.wrappedValue = entry
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
    }

    private func toggleTaskClosedState() {
        if model.task.closedAt == nil {
            model.closeTask()
        } else {
            model.reopenTask()
        }
    }

    private func presentInitialVitalsEntryIfNeeded() {
        guard !didPresentInitialVitalsEntry,
              let initialVitalsEntryID,
              let entry = model.vitalsEntry(id: initialVitalsEntryID)
        else { return }

        editingVitalsEntrySheet.wrappedValue = entry
        didPresentInitialVitalsEntry = true
        onInitialVitalsEntryPresented()
    }

    private func restoreFocusedFieldIfNeeded() {
        guard focusedField == nil,
              let restoredField = TaskDetailFocusField.field(from: focusedFieldRawValue)
        else { return }

        focusedField = restoredField
    }

    /// On a freshly created task, place the cursor in the Task # field so the
    /// scribe can start typing immediately. Runs once, and never steals focus
    /// if the scribe has already tapped another field. The small delay lets the
    /// push navigation settle so the focus request isn't dropped mid-transition.
    private func focusTaskNumberIfNewTask() {
        guard autofocusTaskNumber, !didAutofocusTaskNumber else { return }
        didAutofocusTaskNumber = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if focusedField == nil {
                focusedField = .taskNumber
            }
        }
    }

    private func restoreActiveEditorIfNeeded() {
        guard !didRestoreEditor else { return }
        didRestoreEditor = true

        if let eventID = TaskDetailSceneRestoration.id(from: editingEventIDString),
           let event = model.timelineEvent(id: eventID) {
            editingEventSheet.wrappedValue = event
            return
        }

        if let entryID = TaskDetailSceneRestoration.id(from: editingVitalsEntryIDString),
           let entry = model.vitalsEntry(id: entryID) {
            editingVitalsEntrySheet.wrappedValue = entry
            return
        }

        if isAddingCustomEventStored {
            customEventSheet.wrappedValue = true
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

    private var editingEventSheet: Binding<TimelineEvent?> {
        Binding(
            get: { editingEvent },
            set: { event in
                editingEvent = event
                editingEventIDString = TaskDetailSceneRestoration.storageValue(for: event?.id)
                if event != nil {
                    editingVitalsEntry = nil
                    editingVitalsEntryIDString = ""
                    isAddingCustomEvent = false
                    isAddingCustomEventStored = false
                    customEventIDString = ""
                }
            }
        )
    }

    private var editingVitalsEntrySheet: Binding<VitalsEntry?> {
        Binding(
            get: { editingVitalsEntry },
            set: { entry in
                editingVitalsEntry = entry
                editingVitalsEntryIDString = TaskDetailSceneRestoration.storageValue(for: entry?.id)
                if entry != nil {
                    editingEvent = nil
                    editingEventIDString = ""
                    isAddingCustomEvent = false
                    isAddingCustomEventStored = false
                    customEventIDString = ""
                }
            }
        )
    }

    private var customEventSheet: Binding<Bool> {
        Binding(
            get: { isAddingCustomEvent },
            set: { isPresented in
                isAddingCustomEvent = isPresented
                isAddingCustomEventStored = isPresented
                if isPresented {
                    editingEvent = nil
                    editingEventIDString = ""
                    editingVitalsEntry = nil
                    editingVitalsEntryIDString = ""
                } else {
                    customEventIDString = ""
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

    private func detailTextField(
        _ title: String,
        text: Binding<String>,
        field: TaskDetailFocusField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .font(.body)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: field)
                .disabled(model.isClosed)
                .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

enum TaskDetailSceneRestoration {
    static func id(from storageValue: String) -> UUID? {
        UUID(uuidString: storageValue)
    }

    static func storageValue(for id: UUID?) -> String {
        id?.uuidString ?? ""
    }
}

enum TaskDetailFocusField: String, Hashable {
    case taskNumber
    case subjectName
    case location
    case scribeName
    case notes

    static func field(from storageValue: String) -> TaskDetailFocusField? {
        TaskDetailFocusField(rawValue: storageValue)
    }

    static func storageValue(for field: TaskDetailFocusField?) -> String {
        field?.rawValue ?? ""
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
        if entry.isDraft {
            return "In progress - tap to resume"
        }

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
    var initialEventID: UUID?
    var onEventChanged: (TimelineEvent?) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var timestamp = Date.now
    @State private var event: TimelineEvent?
    @State private var didLoadInitialEvent = false

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
        .task {
            loadInitialEventIfNeeded()
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
                onEventChanged(nil)
            }
            return
        }

        if let event {
            model.updateTimelineEvent(event, label: label)
        } else {
            event = model.addCustomTimelineEvent(label: label, at: timestamp)
            onEventChanged(event)
        }
    }

    private func loadInitialEventIfNeeded() {
        guard !didLoadInitialEvent else { return }
        didLoadInitialEvent = true

        guard let initialEventID,
              let restoredEvent = model.timelineEvent(id: initialEventID)
        else { return }

        event = restoredEvent
        label = restoredEvent.label
        timestamp = restoredEvent.timestamp
        onEventChanged(restoredEvent)
    }
}

/// Full vitals entry form. Every field auto-saves on each keystroke / selection
/// — "Done" only dismisses. All numeric input uses a number pad (no steppers,
/// per charter §4), and categorical fields are single-tap menu pickers.
///
/// When opened on a blank new entry and an earlier reading exists, each field
/// offers the previous value as a one-tap suggestion. Suggestions are opt-in:
/// nothing is carried forward until the scribe taps that field's suggestion,
/// and an unconfirmed suggestion is never saved.
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
    @FocusState private var focusedField: VitalsField?

    /// Ordered numeric fields the keyboard toolbar's Previous / Next step
    /// through. Declaration order matches the on-screen order; categorical
    /// picker rows are intentionally excluded since they don't use the keyboard.
    private enum VitalsField: Hashable, CaseIterable {
        case heartRate, systolic, diastolic, oxygenSaturation, respiratoryRate, temperature
        case gcsEye, gcsVerbal, gcsMotor
        case leftPupilSize, rightPupilSize
        case pain
    }

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
                    intRow("Heart rate (bpm)", \.heartRate, field: .heartRate)
                    bloodPressureRow()
                    intRow("SpO₂ (%)", \.oxygenSaturation, field: .oxygenSaturation, in: 0...100)
                    intRow("Respiratory rate", \.respiratoryRate, field: .respiratoryRate)
                    decimalRow("Temperature (°C)", "temperature", \.temperature, field: .temperature)
                }

                Section("Glasgow Coma Scale") {
                    intRow("Eye (1–4)", \.gcsEye, field: .gcsEye, in: VitalsRange.gcsEye)
                    intRow("Verbal (1–5)", \.gcsVerbal, field: .gcsVerbal, in: VitalsRange.gcsVerbal)
                    intRow("Motor (1–6)", \.gcsMotor, field: .gcsMotor, in: VitalsRange.gcsMotor)
                    LabeledContent("Total", value: entry.gcsTotal.map { String($0) } ?? "—")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .accessibilityLabel("GCS total")
                        .accessibilityValue(entry.gcsTotal.map { String($0) } ?? "Incomplete")
                }

                Section("Pupils") {
                    decimalRow("Left size (mm)", "leftPupilSize", \.leftPupilSize, field: .leftPupilSize)
                    optionRow("Left reactivity", \.leftPupilReactivity, options: VitalsFieldOptions.pupilReactivity)
                    decimalRow("Right size (mm)", "rightPupilSize", \.rightPupilSize, field: .rightPupilSize)
                    optionRow("Right reactivity", \.rightPupilReactivity, options: VitalsFieldOptions.pupilReactivity)
                }

                Section("Other") {
                    intRow("Pain (0–10)", \.painScore, field: .pain, in: VitalsRange.pain)
                    optionRow("Capillary refill", \.capillaryRefill, options: VitalsFieldOptions.capillaryRefill)
                    optionRow("LOC / AVPU", \.levelOfConsciousness, options: VitalsFieldOptions.levelOfConsciousness)
                }

                Section("Skin") {
                    optionRow("Colour", \.skinColour, options: VitalsFieldOptions.skinColour)
                    optionRow("Temperature", \.skinTemperature, options: VitalsFieldOptions.skinTemperature)
                    optionRow("Moisture", \.skinMoisture, options: VitalsFieldOptions.skinMoisture)
                }

                if entry.isDraft {
                    Section {
                        Button(role: .destructive) {
                            if model.discardVitalsEntry(entry) {
                                dismiss()
                            }
                        } label: {
                            Label("Discard in-progress entry", systemImage: "trash")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .accessibilityLabel("Discard in-progress vitals entry")
                    }
                }
            }
            .navigationTitle("Vitals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if model.finishVitalsEntry(entry) {
                            dismiss()
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }

                    Spacer()

                    Button {
                        focusAdjacentField(forward: false)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!canFocusField(forward: false))
                    .accessibilityLabel("Previous field")

                    Button {
                        focusAdjacentField(forward: true)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!canFocusField(forward: true))
                    .accessibilityLabel("Next field")
                }
            }
            .interactiveDismissDisabled(entry.isDraft)
            .task {
                if !prefillConfigured {
                    startedBlank = !entry.hasClinicalData
                    prefillConfigured = true
                }
            }
        }
    }

    // MARK: - Keyboard field navigation

    private func canFocusField(forward: Bool) -> Bool {
        guard let current = focusedField,
              let index = VitalsField.allCases.firstIndex(of: current) else { return false }
        return forward ? index + 1 < VitalsField.allCases.count : index > 0
    }

    private func focusAdjacentField(forward: Bool) {
        guard let current = focusedField,
              let index = VitalsField.allCases.firstIndex(of: current) else { return }
        let target = forward ? index + 1 : index - 1
        guard VitalsField.allCases.indices.contains(target) else { return }
        focusedField = VitalsField.allCases[target]
    }

    // MARK: - Prefill

    private func prefillBanner(_ source: VitalsEntry) -> some View {
        Section {
            Text("Last reading at \(source.timestamp.formatted(date: .omitted, time: .shortened)). Tap each field's suggestion to copy that value.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
        field: VitalsField,
        in range: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            TextField(title, text: intField(keyPath, in: range))
                .keyboardType(.numberPad)
                .font(.body)
                .focused($focusedField, equals: field)
                .accessibilityLabel(title)
            suggestion(title, keyPath) { String($0) }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }

    /// Systolic and diastolic on one line, separated by a slash — the way
    /// blood pressure is spoken and written (e.g. 120/80). The two values
    /// remain independent stored fields.
    private func bloodPressureRow() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Blood pressure (mmHg)")
            HStack(spacing: 10) {
                TextField("Systolic", text: intField(\.systolicBloodPressure))
                    .keyboardType(.numberPad)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .focused($focusedField, equals: .systolic)
                    .accessibilityLabel("Systolic blood pressure")
                Text("/")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Diastolic", text: intField(\.diastolicBloodPressure))
                    .keyboardType(.numberPad)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .focused($focusedField, equals: .diastolic)
                    .accessibilityLabel("Diastolic blood pressure")
            }
            HStack(spacing: 16) {
                suggestion("Systolic BP", \.systolicBloodPressure) { String($0) }
                suggestion("Diastolic BP", \.diastolicBloodPressure) { String($0) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }

    private func decimalRow(
        _ title: String,
        _ key: String,
        _ keyPath: ReferenceWritableKeyPath<VitalsEntry, Double?>,
        field: VitalsField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            TextField(title, text: decimalField(key, keyPath))
                .keyboardType(.decimalPad)
                .font(.body)
                .focused($focusedField, equals: field)
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
