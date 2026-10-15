import XCTest
@testable import SARLog

final class DMSConverterTests: XCTestCase {

    func testParseNorthEast() {
        let coord = DMSConverter.parse("41°24'12.2\"N, 2°10'26.5\"E")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40339, longitude: 2.17403), accuracy: 1e-4))
    }

    func testParseSouthWest() {
        let coord = DMSConverter.parse("33°52'7.68\"S, 151°12'33.48\"W")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: -151.2093), accuracy: 1e-4))
    }

    func testParseWithSpaces() {
        let coord = DMSConverter.parse("41° 24' 12.2\" N, 2° 10' 26.5\" E")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40339, longitude: 2.17403), accuracy: 1e-4))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(DMSConverter.parse("not a coordinate"))
        XCTAssertNil(DMSConverter.parse(""))
    }

    func testFormatNorthEast() {
        let result = DMSConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertEqual(result, "41°24'12.1680\"N, 2°10'26.5080\"E")
    }

    func testFormatSouthWest() {
        let result = DMSConverter.format(Coordinate(latitude: -33.8688, longitude: -151.2093))
        XCTAssertEqual(result, "33°52'7.6800\"S, 151°12'33.4800\"W")
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = DMSConverter.format(original)
        let parsed = DMSConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-4))
    }
}
