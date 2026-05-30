import Foundation
import SwiftData

@Model
final class TimelineEvent {
    @Attribute(.unique) var id: UUID
    var taskId: UUID
    var label: String
    var timestamp: Date
    var isCustom: Bool

    init(
        id: UUID = UUID(),
        taskId: UUID,
        label: String,
        timestamp: Date = .now,
        isCustom: Bool = false
    ) {
        self.id = id
        self.taskId = taskId
        self.label = label
        self.timestamp = timestamp
        self.isCustom = isCustom
    }
}
