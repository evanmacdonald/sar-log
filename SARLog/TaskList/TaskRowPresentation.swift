import Foundation

enum TaskRowPresentation {
    static func title(taskNumber: String, subjectName: String) -> String {
        let number = taskNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !number.isEmpty {
            return number
        }
        let subject = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !subject.isEmpty {
            return subject
        }
        return "Untitled task"
    }

    static func subtitle(taskNumber: String, subjectName: String) -> String? {
        let number = taskNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty, !subject.isEmpty else {
            return nil
        }
        return subject
    }
}
