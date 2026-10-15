import XCTest
@testable import SARLog

final class CoordinateFormatDetectionTests: XCTestCase {

    func testDetectsStandardDD() {
        XCTAssertEqual(CoordinateFormat.detect("41.40338, 2.17403"), .dd)
    }

    func testDetectsNegativeDD() {
        XCTAssertEqual(CoordinateFormat.detect("-33.8688, 151.2093"), .dd)
    }

    func testDetectsStandardDMS() {
        XCTAssertEqual(CoordinateFormat.detect("41°24'12.17\"N, 2°10'26.51\"E"), .dms)
    }

    func testDetectsLenientDMS() {
        XCTAssertEqual(CoordinateFormat.detect("50 26 21.0700, -114 56 11.6474"), .dms)
    }

    func testDetectsStandardDDM() {
        XCTAssertEqual(CoordinateFormat.detect("41°24.2028'N, 2°10.4418'E"), .ddm)
    }

    func testDetectsUTM() {
        XCTAssertEqual(CoordinateFormat.detect("31T 430960 4583867"), .utm)
    }

    func testDetectsMGRS() {
        XCTAssertEqual(CoordinateFormat.detect("31TDF3095983866"), .mgrs)
    }

    func testDetectsMGRSWithSpaces() {
        XCTAssertEqual(CoordinateFormat.detect("31T DF 30959 83866"), .mgrs)
    }

    func testDetectsPlusCode() {
        XCTAssertEqual(CoordinateFormat.detect("8FWC2345+G9"), .plusCode)
    }

    func testReturnsNilForGarbage() {
        XCTAssertNil(CoordinateFormat.detect("hello world"))
    }

    func testReturnsNilForEmpty() {
        XCTAssertNil(CoordinateFormat.detect(""))
    }

    func testReturnsNilForWhitespace() {
        XCTAssertNil(CoordinateFormat.detect("   "))
    }

    func testLenientDMSParsesCorrectly() {
        let coord = DMSConverter.parse("50 26 21.0700, -114 56 11.6474")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 50.439186, longitude: -114.936569), accuracy: 1e-4))
    }

    func testLenientDMSNegativeLatitude() {
        let coord = DMSConverter.parse("-33 52 7.68, 151 12 33.48")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093), accuracy: 1e-4))
    }

    func testLenientDMSFormatsCorrectly() {
        let coord = DMSConverter.parse("50 26 21.0700, -114 56 11.6474")!
        let formatted = DMSConverter.format(coord)
        XCTAssertTrue(formatted.contains("°"))
        XCTAssertTrue(formatted.contains("'"))
        XCTAssertTrue(formatted.contains("\""))
    }

    func testLenientDDMParsesCorrectly() {
        let coord = DDMConverter.parse("50 26.35, -114 56.19")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 50.439167, longitude: -114.9365), accuracy: 1e-4))
    }
}
