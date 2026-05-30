import XCTest
@testable import SARLog

final class TaskDetailViewTests: XCTestCase {
    @MainActor
    func testContentBuildsEditableFieldsWithoutMapsAction() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask(location: "Trailhead")
        let model = TaskDetailViewModel(task: task, repository: repository)

        _ = TaskDetailContent(model: model).body
    }

    @MainActor
    func testContentBuildsMapsActionForCoordinateLocation() throws {
        let container = try SARLogModelContainer.inMemory()
        let repository = TaskRepository(context: container.mainContext)
        let task = try repository.createTask(location: "49.123, -123.456")
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
