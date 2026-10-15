import XCTest
@testable import SARLog

final class MGRSConverterTests: XCTestCase {

    func testParseNorthernHemisphere() {
        let coord = MGRSConverter.parse("31TDF3095983866")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testParseWithSpaces() {
        let coord = MGRSConverter.parse("31T DF 30959 83866")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testParseSouthernHemisphere() {
        let coord = MGRSConverter.parse("56HLH3436850948")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093), accuracy: 1e-3))
    }

    func testParseWesternHemisphere() {
        let coord = MGRSConverter.parse("18TWL8395907350")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 40.7128, longitude: -74.0060), accuracy: 1e-3))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(MGRSConverter.parse("not a coordinate"))
        XCTAssertNil(MGRSConverter.parse(""))
        XCTAssertNil(MGRSConverter.parse("99TDF3095983866"))
    }

    func testParseLowerCase() {
        let coord = MGRSConverter.parse("31tdf3095983866")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testFormatNorthernHemisphere() {
        let result = MGRSConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertTrue(result.hasPrefix("31T"))
        XCTAssertTrue(result.contains("DF"))
    }

    func testFormatSouthernHemisphere() {
        let result = MGRSConverter.format(Coordinate(latitude: -33.8688, longitude: 151.2093))
        XCTAssertTrue(result.hasPrefix("56H"))
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = MGRSConverter.format(original)
        let parsed = MGRSConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testRoundTripSouthernHemisphere() {
        let original = Coordinate(latitude: -33.8688, longitude: 151.2093)
        let formatted = MGRSConverter.format(original)
        let parsed = MGRSConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testRoundTripWesternHemisphere() {
        let original = Coordinate(latitude: 40.7128, longitude: -74.0060)
        let formatted = MGRSConverter.format(original)
        let parsed = MGRSConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }
}
