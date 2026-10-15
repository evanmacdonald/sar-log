import XCTest
@testable import SARLog

final class UTMConverterTests: XCTestCase {

    func testParseNorthernHemisphere() {
        let coord = UTMConverter.parse("31T 430960 4583867")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testParseSouthernHemisphere() {
        let coord = UTMConverter.parse("56H 334369 6250948")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093), accuracy: 1e-3))
    }

    func testParseWesternHemisphere() {
        let coord = UTMConverter.parse("18T 583959 4507351")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 40.7128, longitude: -74.0060), accuracy: 1e-3))
    }

    func testParseEquator() {
        let coord = UTMConverter.parse("37N 500000 0")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 0.0, longitude: 39.0), accuracy: 1e-3))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(UTMConverter.parse("not a coordinate"))
        XCTAssertNil(UTMConverter.parse(""))
        XCTAssertNil(UTMConverter.parse("99T 500000 5000000"))
        XCTAssertNil(UTMConverter.parse("31I 500000 5000000"))
        XCTAssertNil(UTMConverter.parse("31O 500000 5000000"))
    }

    func testFormatNorthernHemisphere() {
        let result = UTMConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertTrue(result.hasPrefix("31T"))
        let parsed = UTMConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testFormatSouthernHemisphere() {
        let result = UTMConverter.format(Coordinate(latitude: -33.8688, longitude: 151.2093))
        XCTAssertTrue(result.hasPrefix("56H"))
        let parsed = UTMConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093), accuracy: 1e-3))
    }

    func testFormatWesternHemisphere() {
        let result = UTMConverter.format(Coordinate(latitude: 40.7128, longitude: -74.0060))
        XCTAssertTrue(result.hasPrefix("18T"))
    }

    /// Longitude exactly on the antimeridian would otherwise produce zone 61,
    /// which no UTM parser accepts and which breaks the Map/Convert round
    /// trip. Clamp to zone 60.
    func testFormatAtAntimeridianClampsToZone60() {
        let result = UTMConverter.format(Coordinate(latitude: 0.0, longitude: 180.0))
        XCTAssertFalse(result.hasPrefix("61"), "UTM zone must not exceed 60; got \(result)")
        XCTAssertTrue(result.hasPrefix("60"), "Expected zone 60 at the antimeridian; got \(result)")

        // And the output must round-trip through our own parser.
        let parsed = UTMConverter.parse(result)
        XCTAssertNotNil(parsed, "Antimeridian UTM output must be re-parseable; got \(result)")
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = UTMConverter.format(original)
        let parsed = UTMConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testRoundTripNegativeCoordinates() {
        let original = Coordinate(latitude: -33.8688, longitude: -151.2093)
        let formatted = UTMConverter.format(original)
        let parsed = UTMConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }
}
