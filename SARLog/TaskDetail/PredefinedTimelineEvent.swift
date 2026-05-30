import Foundation

struct PredefinedTimelineEvent: Identifiable, Equatable {
    let label: String
    let systemImage: String

    var id: String {
        label
    }

    static let all: [PredefinedTimelineEvent] = [
        PredefinedTimelineEvent(label: "Callout from ECC", systemImage: "phone.badge.waveform"),
        PredefinedTimelineEvent(label: "Left hall", systemImage: "figure.walk.departure"),
        PredefinedTimelineEvent(label: "Arrived staging", systemImage: "mappin.and.ellipse"),
        PredefinedTimelineEvent(label: "Departed staging", systemImage: "arrow.up.right.circle"),
        PredefinedTimelineEvent(label: "On scene", systemImage: "cross.case"),
        PredefinedTimelineEvent(label: "Returning to base", systemImage: "house")
    ]
}
