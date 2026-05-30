import XCTest
@testable import SARLog

final class SARLogTests: XCTestCase {
    func testReadinessMessageMatchesTaskState() {
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: false), "Ready for task logging.")
        XCTAssertEqual(FieldConditionText.readinessMessage(hasActiveTask: true), "Task logging in progress.")
    }

    // MARK: - GCS total

    func testGCSTotalIsNilUntilAllThreeComponentsPresent() {
        let entry = VitalsEntry(taskId: UUID())
        XCTAssertNil(entry.gcsTotal)

        entry.gcsEye = 4
        entry.gcsVerbal = 5
        XCTAssertNil(entry.gcsTotal, "Partial GCS should not report a misleading score")

        entry.gcsMotor = 6
        XCTAssertEqual(entry.gcsTotal, 15)
    }

    func testGCSTotalSumsComponents() {
        let entry = VitalsEntry(taskId: UUID(), gcsEye: 3, gcsVerbal: 4, gcsMotor: 5)
        XCTAssertEqual(entry.gcsTotal, 12)
    }

    // MARK: - Numeric input validation

    func testBoundedIntParsesDigitsOnly() {
        XCTAssertEqual(VitalsInput.boundedInt("72"), 72)
        XCTAssertEqual(VitalsInput.boundedInt("1 2 0"), 120)
        XCTAssertNil(VitalsInput.boundedInt(""))
        XCTAssertNil(VitalsInput.boundedInt("abc"))
    }

    func testBoundedIntRejectsZeroWhenUnbounded() {
        XCTAssertNil(VitalsInput.boundedInt("0"))
    }

    func testBoundedIntClampsIntoRange() {
        XCTAssertEqual(VitalsInput.boundedInt("9", in: VitalsRange.gcsEye), 4)
        XCTAssertEqual(VitalsInput.boundedInt("0", in: VitalsRange.gcsEye), 1)
        XCTAssertEqual(VitalsInput.boundedInt("3", in: VitalsRange.gcsEye), 3)
        XCTAssertEqual(VitalsInput.boundedInt("0", in: VitalsRange.pain), 0)
        XCTAssertEqual(VitalsInput.boundedInt("99", in: VitalsRange.pain), 10)
        XCTAssertEqual(VitalsInput.boundedInt("100", in: 0...100), 100)
    }

    func testDecimalParsing() {
        XCTAssertEqual(VitalsInput.decimal("36.7"), 36.7)
        XCTAssertEqual(VitalsInput.decimal("36,7"), 36.7)
        XCTAssertEqual(VitalsInput.decimal(" 4 "), 4)
        XCTAssertNil(VitalsInput.decimal(""))
        XCTAssertNil(VitalsInput.decimal("abc"))
    }

    func testFieldOptionsCoverCharterCategories() {
        XCTAssertEqual(VitalsFieldOptions.pupilReactivity, ["Reactive", "Sluggish", "Fixed"])
        XCTAssertEqual(VitalsFieldOptions.levelOfConsciousness, ["Alert", "Verbal", "Pain", "Unresponsive"])
        XCTAssertFalse(VitalsFieldOptions.skinColour.isEmpty)
        XCTAssertFalse(VitalsFieldOptions.skinTemperature.isEmpty)
        XCTAssertFalse(VitalsFieldOptions.skinMoisture.isEmpty)
        XCTAssertFalse(VitalsFieldOptions.capillaryRefill.isEmpty)
    }

    // MARK: - hasClinicalData (drives prefill eligibility)

    func testHasClinicalDataFalseForFreshEntry() {
        let entry = VitalsEntry(taskId: UUID())
        XCTAssertFalse(entry.hasClinicalData)
    }

    func testHasClinicalDataTrueWhenAnyFieldSet() {
        let numeric = VitalsEntry(taskId: UUID())
        numeric.respiratoryRate = 16
        XCTAssertTrue(numeric.hasClinicalData)

        let categorical = VitalsEntry(taskId: UUID())
        categorical.skinColour = "Pale"
        XCTAssertTrue(categorical.hasClinicalData)
    }
}
