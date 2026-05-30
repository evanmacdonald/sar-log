import Foundation
import SwiftData

@Model
final class VitalsEntry {
    @Attribute(.unique) var id: UUID
    var taskId: UUID
    var timestamp: Date
    var heartRate: Int?
    var systolicBloodPressure: Int?
    var diastolicBloodPressure: Int?
    var oxygenSaturation: Int?
    var respiratoryRate: Int?
    var temperature: Double?
    var gcsEye: Int?
    var gcsVerbal: Int?
    var gcsMotor: Int?
    var leftPupilSize: Double?
    var leftPupilReactivity: String?
    var rightPupilSize: Double?
    var rightPupilReactivity: String?
    var painScore: Int?
    var capillaryRefill: String?
    var skinColour: String?
    var skinTemperature: String?
    var skinMoisture: String?
    var levelOfConsciousness: String?

    init(
        id: UUID = UUID(),
        taskId: UUID,
        timestamp: Date = .now,
        heartRate: Int? = nil,
        systolicBloodPressure: Int? = nil,
        diastolicBloodPressure: Int? = nil,
        oxygenSaturation: Int? = nil,
        respiratoryRate: Int? = nil,
        temperature: Double? = nil,
        gcsEye: Int? = nil,
        gcsVerbal: Int? = nil,
        gcsMotor: Int? = nil,
        leftPupilSize: Double? = nil,
        leftPupilReactivity: String? = nil,
        rightPupilSize: Double? = nil,
        rightPupilReactivity: String? = nil,
        painScore: Int? = nil,
        capillaryRefill: String? = nil,
        skinColour: String? = nil,
        skinTemperature: String? = nil,
        skinMoisture: String? = nil,
        levelOfConsciousness: String? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.systolicBloodPressure = systolicBloodPressure
        self.diastolicBloodPressure = diastolicBloodPressure
        self.oxygenSaturation = oxygenSaturation
        self.respiratoryRate = respiratoryRate
        self.temperature = temperature
        self.gcsEye = gcsEye
        self.gcsVerbal = gcsVerbal
        self.gcsMotor = gcsMotor
        self.leftPupilSize = leftPupilSize
        self.leftPupilReactivity = leftPupilReactivity
        self.rightPupilSize = rightPupilSize
        self.rightPupilReactivity = rightPupilReactivity
        self.painScore = painScore
        self.capillaryRefill = capillaryRefill
        self.skinColour = skinColour
        self.skinTemperature = skinTemperature
        self.skinMoisture = skinMoisture
        self.levelOfConsciousness = levelOfConsciousness
    }

    /// Glasgow Coma Scale total. Only meaningful once all three components
    /// (eye, verbal, motor) are present, so it stays `nil` until then rather
    /// than reporting a misleading partial score.
    var gcsTotal: Int? {
        guard let gcsEye, let gcsVerbal, let gcsMotor else { return nil }
        return gcsEye + gcsVerbal + gcsMotor
    }
}

/// Valid ranges for the numeric vitals fields. Used to clamp number-pad input
/// so a fat-fingered entry can't store an impossible value (e.g. GCS eye of 9).
enum VitalsRange {
    static let gcsEye = 1...4
    static let gcsVerbal = 1...5
    static let gcsMotor = 1...6
    static let pain = 0...10
}

/// Pure parsing/validation helpers for vitals number-pad input. Kept free of
/// SwiftUI so the rules are unit-testable.
enum VitalsInput {
    /// Parse digits into a positive integer, returning `nil` for empty/zero
    /// input. When `range` is supplied the value is clamped into it.
    static func boundedInt(_ text: String, in range: ClosedRange<Int>? = nil) -> Int? {
        let digits = text.filter(\.isNumber)
        guard let value = Int(digits) else { return nil }
        guard let range else {
            return value > 0 ? value : nil
        }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    /// Parse a decimal field (temperature, pupil size). Accepts either `.` or
    /// `,` as the separator and returns `nil` for empty/invalid input.
    static func decimal(_ text: String) -> Double? {
        let trimmed = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        if trimmed.isEmpty { return nil }
        return Double(trimmed)
    }
}

/// Picker option lists for the categorical vitals fields. Stored on the model
/// as free-form `String?`, but entered from a fixed list to keep field entry
/// to a single tap.
enum VitalsFieldOptions {
    static let pupilReactivity = ["Reactive", "Sluggish", "Fixed"]
    static let capillaryRefill = ["< 2 sec", "> 2 sec"]
    static let skinColour = ["Normal", "Pale", "Flushed", "Cyanotic", "Jaundiced", "Mottled"]
    static let skinTemperature = ["Warm", "Hot", "Cool", "Cold"]
    static let skinMoisture = ["Dry", "Moist", "Diaphoretic"]
    static let levelOfConsciousness = ["Alert", "Verbal", "Pain", "Unresponsive"]
}
