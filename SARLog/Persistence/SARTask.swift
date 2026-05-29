import Foundation
import SwiftData

@Model
final class SARTask {
    @Attribute(.unique) var id: UUID
    var taskNumber: String
    var subjectName: String
    var location: String
    var scribeName: String
    var notes: String
    var createdAt: Date
    var closedAt: Date?

    init(
        id: UUID = UUID(),
        taskNumber: String = "",
        subjectName: String = "",
        location: String = "",
        scribeName: String = "",
        notes: String = "",
        createdAt: Date = .now,
        closedAt: Date? = nil
    ) {
        self.id = id
        self.taskNumber = taskNumber
        self.subjectName = subjectName
        self.location = location
        self.scribeName = scribeName
        self.notes = notes
        self.createdAt = createdAt
        self.closedAt = closedAt
    }
}
