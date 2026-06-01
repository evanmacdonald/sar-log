import Foundation

struct SARLogPDFReport {
    var taskNumber: String
    var taskName: String
    var logKeeper: String
    var location: String
    var periodStart: Date
    var periodEnd: Date
    var generatedAt: Date
    var rows: [SARLogPDFLogRow]
    var notes: String

    var hasNotesAppendix: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SARLogPDFLogRow: Identifiable, Equatable {
    enum Source: String, Comparable {
        case timeline
        case vitals

        static func < (lhs: Source, rhs: Source) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    var id: UUID
    var timestamp: Date
    var subject: String
    var source: Source
}

enum SARLogPDFReportBuilder {
    static func makeReport(
        task: SARTask,
        timelineEvents: [TimelineEvent],
        vitalsEntries: [VitalsEntry],
        generatedAt: Date = .now
    ) -> SARLogPDFReport {
        let timelineRows = timelineEvents.map { event in
            SARLogPDFLogRow(
                id: event.id,
                timestamp: event.timestamp,
                subject: event.label,
                source: .timeline
            )
        }

        let vitalsRows = vitalsEntries.map { entry in
            SARLogPDFLogRow(
                id: entry.id,
                timestamp: entry.timestamp,
                subject: vitalsSummary(for: entry),
                source: .vitals
            )
        }

        let rows = (timelineRows + vitalsRows).sorted { first, second in
            if first.timestamp != second.timestamp {
                return first.timestamp < second.timestamp
            }
            if first.source != second.source {
                return first.source < second.source
            }
            if first.subject != second.subject {
                return first.subject < second.subject
            }
            return first.id.uuidString < second.id.uuidString
        }

        return SARLogPDFReport(
            taskNumber: task.taskNumber,
            taskName: task.subjectName,
            logKeeper: task.scribeName,
            location: task.location,
            periodStart: task.createdAt,
            periodEnd: task.closedAt ?? generatedAt,
            generatedAt: generatedAt,
            rows: rows,
            notes: task.notes
        )
    }

    static func vitalsSummary(for entry: VitalsEntry) -> String {
        var parts: [String] = []

        if let heartRate = entry.heartRate {
            parts.append("HR \(heartRate)")
        }
        if let systolic = entry.systolicBloodPressure,
           let diastolic = entry.diastolicBloodPressure {
            parts.append("BP \(systolic)/\(diastolic)")
        } else if let systolic = entry.systolicBloodPressure {
            parts.append("SBP \(systolic)")
        } else if let diastolic = entry.diastolicBloodPressure {
            parts.append("DBP \(diastolic)")
        }
        if let oxygenSaturation = entry.oxygenSaturation {
            parts.append("SpO2 \(oxygenSaturation)%")
        }
        if let respiratoryRate = entry.respiratoryRate {
            parts.append("RR \(respiratoryRate)")
        }
        if let temperature = entry.temperature {
            parts.append("Temp \(formatDecimal(temperature)) deg C")
        }

        let gcsParts = [
            entry.gcsEye.map { "E\($0)" },
            entry.gcsVerbal.map { "V\($0)" },
            entry.gcsMotor.map { "M\($0)" }
        ].compactMap { $0 }
        if let total = entry.gcsTotal {
            parts.append("GCS \(total) (\(gcsParts.joined(separator: " ")))")
        } else if !gcsParts.isEmpty {
            parts.append("GCS \(gcsParts.joined(separator: " "))")
        }

        let leftPupil = pupilSummary(
            side: "L",
            size: entry.leftPupilSize,
            reactivity: entry.leftPupilReactivity
        )
        let rightPupil = pupilSummary(
            side: "R",
            size: entry.rightPupilSize,
            reactivity: entry.rightPupilReactivity
        )
        let pupilParts = [leftPupil, rightPupil].compactMap { $0 }
        if !pupilParts.isEmpty {
            parts.append("Pupils \(pupilParts.joined(separator: ", "))")
        }

        if let painScore = entry.painScore {
            parts.append("Pain \(painScore)/10")
        }
        if let capillaryRefill = entry.capillaryRefill {
            parts.append("Cap refill \(capillaryRefill)")
        }

        let skinParts = [
            entry.skinColour,
            entry.skinTemperature,
            entry.skinMoisture
        ].compactMap { $0 }
        if !skinParts.isEmpty {
            parts.append("Skin \(skinParts.joined(separator: "/"))")
        }

        if let levelOfConsciousness = entry.levelOfConsciousness {
            parts.append("LOC \(levelOfConsciousness)")
        }

        if parts.isEmpty {
            return entry.isDraft ? "Vitals: in progress, no values recorded" : "Vitals: no values recorded"
        }

        let status = entry.isDraft ? "Vitals (in progress): " : "Vitals: "
        return status + parts.joined(separator: "; ")
    }

    private static func pupilSummary(side: String, size: Double?, reactivity: String?) -> String? {
        switch (size, reactivity) {
        case let (.some(size), .some(reactivity)):
            return "\(side) \(formatDecimal(size)) mm \(reactivity)"
        case let (.some(size), .none):
            return "\(side) \(formatDecimal(size)) mm"
        case let (.none, .some(reactivity)):
            return "\(side) \(reactivity)"
        case (.none, .none):
            return nil
        }
    }

    private static func formatDecimal(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.0001 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", value)
    }
}
