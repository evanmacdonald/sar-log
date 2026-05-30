import XCTest
@testable import SARLog

final class TaskDetailViewTests: XCTestCase {
    @MainActor
    func testContentBuildsEditableFields() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask(location: "Eagle Ridge, Coquitlam")
        let model = TaskDetailViewModel(task: task, repository: repository)

        _ = TaskDetailContent(model: model).body
    }

    @MainActor
    func testContentBuildsTimelineList() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        try repository.createTimelineEvent(
            for: task,
            label: "Callout from ECC",
            timestamp: Date(timeIntervalSince1970: 100)
        )
        let model = TaskDetailViewModel(task: task, repository: repository)

        _ = TaskDetailContent(model: model).body
    }

    @MainActor
    func testContentBuildsPredefinedEventActions() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)

        _ = TaskDetailContent(model: model).body
    }

    @MainActor
    func testEventEditorBuildsForExistingEvent() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask()
        let model = TaskDetailViewModel(task: task, repository: repository)
        let event = try XCTUnwrap(model.addCustomTimelineEvent(label: "Custom", at: Date(timeIntervalSince1970: 100)))

        _ = TimelineEventEditor(model: model, event: event).body
    }
}
