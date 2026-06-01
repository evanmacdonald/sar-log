import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model: TaskListViewModel?

    var body: some View {
        Group {
            if let model {
                TaskListContent(model: model)
            } else {
                ProgressView()
            }
        }
        .task {
            if model == nil {
                model = TaskListViewModel(context: modelContext)
            }
            model?.refresh()
        }
    }
}

struct TaskListContent: View {
    @Bindable var model: TaskListViewModel
    @SceneStorage("TaskList.selectedTaskID") private var selectedTaskIDString = ""
    @State private var path: [SARTask] = []
    @State private var pendingDeletion: SARTask?
    @State private var resumeVitalsEntryID: UUID?
    @State private var didRestorePath = false

    var body: some View {
        NavigationStack(path: navigationPath) {
            Group {
                if model.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .navigationDestination(for: SARTask.self) { task in
                TaskDetailView(
                    task: task,
                    initialVitalsEntryID: resumeVitalsEntryID
                ) {
                    resumeVitalsEntryID = nil
                }
            }
            .safeAreaInset(edge: .bottom) {
                newTaskButton
            }
            .onAppear {
                model.refresh()
                restoreNavigationPathIfNeeded()
            }
            .alert("Save problem", isPresented: errorBinding) {
                Button("OK") {
                    model.errorMessage = nil
                }
            } message: {
                Text(model.errorMessage ?? "Try again before leaving this screen.")
            }
            .confirmationDialog(
                "Delete this task?",
                isPresented: deletionBinding,
                titleVisibility: .visible,
                presenting: pendingDeletion
            ) { task in
                Button("Delete task", role: .destructive) {
                    model.delete(task)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This permanently removes the task and its log. This can't be undone.")
            }
            .alert(
                "Resume vitals entry?",
                isPresented: vitalsRecoveryBinding,
                presenting: model.pendingVitalsDraft
            ) { draft in
                Button("Resume") {
                    resumeVitalsEntryID = draft.entry.id
                    if !path.contains(where: { $0.id == draft.task.id }) {
                        navigationPath.wrappedValue.append(draft.task)
                    }
                    _ = model.resumePendingVitalsDraft()
                }
                Button("Discard", role: .destructive) {
                    model.discardPendingVitalsDraft()
                }
            } message: { draft in
                Text("SAR Log stopped while a vitals entry was open for \(draft.taskTitle). Resume it or discard the in-progress entry.")
            }
        }
    }

    private var navigationPath: Binding<[SARTask]> {
        Binding(
            get: { path },
            set: { newValue in
                path = newValue
                selectedTaskIDString = TaskSceneRestoration.storageValue(for: newValue.last)
            }
        )
    }

    private func restoreNavigationPathIfNeeded() {
        guard !didRestorePath else { return }
        didRestorePath = true

        guard path.isEmpty,
              let taskID = TaskSceneRestoration.taskID(from: selectedTaskIDString),
              let restoredTask = model.task(id: taskID)
        else {
            selectedTaskIDString = ""
            return
        }

        path = [restoredTask]
    }

    private var taskList: some View {
        List {
            if !model.activeTasks.isEmpty {
                Section("Active") {
                    ForEach(model.activeTasks) { task in
                        row(for: task)
                    }
                }
            }
            if !model.closedTasks.isEmpty {
                Section("Closed") {
                    ForEach(model.closedTasks) { task in
                        row(for: task)
                    }
                }
            }
        }
    }

    private func row(for task: SARTask) -> some View {
        NavigationLink(value: task) {
            TaskRow(task: task)
        }
        .contextMenu {
            if task.closedAt == nil {
                Button {
                    model.close(task)
                } label: {
                    Label("Close task", systemImage: "checkmark.circle")
                }
            } else {
                Button {
                    model.reopen(task)
                } label: {
                    Label("Reopen task", systemImage: "arrow.uturn.backward.circle")
                }
            }
            Button(role: .destructive) {
                pendingDeletion = task
            } label: {
                Label("Delete task", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No tasks yet", systemImage: "cross.case")
        } description: {
            Text("Start a new task when you're called out.")
        }
    }

    private var newTaskButton: some View {
        Button {
            if let task = model.createTask() {
                navigationPath.wrappedValue.append(task)
            }
        } label: {
            Label("New task", systemImage: "plus.circle.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .background(.bar)
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    pendingDeletion = nil
                }
            }
        )
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

    private var vitalsRecoveryBinding: Binding<Bool> {
        Binding(
            get: { model.pendingVitalsDraft != nil },
            set: { newValue in
                if !newValue {
                    _ = model.resumePendingVitalsDraft()
                }
            }
        )
    }
}

struct TaskRow: View {
    let task: SARTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(TaskRowPresentation.title(taskNumber: task.taskNumber, subjectName: task.subjectName))
                .font(.headline)
            if let subtitle = TaskRowPresentation.subtitle(taskNumber: task.taskNumber, subjectName: task.subjectName) {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(task.createdAt, format: .dateTime.month().day().hour().minute())
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
