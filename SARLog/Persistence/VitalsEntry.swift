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
}
