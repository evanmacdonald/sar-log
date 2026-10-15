import XCTest
@testable import SARLog

final class DDMConverterTests: XCTestCase {

    func testParseNorthEast() {
        let coord = DDMConverter.parse("41°24.2028'N, 2°10.4418'E")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403)))
    }

    func testParseSouthWest() {
        let coord = DDMConverter.parse("33°52.1280'S, 151°12.5580'W")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: -151.2093)))
    }

    func testParseWithSpaces() {
        let coord = DDMConverter.parse("41° 24.2028' N, 2° 10.4418' E")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403)))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(DDMConverter.parse("not a coordinate"))
        XCTAssertNil(DDMConverter.parse(""))
    }

    /// The documented acceptance input in PR 17 — the exact format BC SAR
    /// dispatchers typically read out — must parse and feed Map/Convert.
    func testParseDirectionalWhitespaceSeparated() {
        let coord = DDMConverter.parse("30 17.11'N 095 28.07'W")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(
            to: Coordinate(latitude: 30.285167, longitude: -95.467833),
            accuracy: 1e-4
        ))
    }

    func testParseDirectionalSouthernEastern() {
        let coord = DDMConverter.parse("33 52.128'S 151 12.558'E")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(
            to: Coordinate(latitude: -33.8688, longitude: 151.2093),
            accuracy: 1e-4
        ))
    }

    func testParseDirectionalLowercaseHemisphere() {
        let coord = DDMConverter.parse("30 17.11'n 095 28.07'w")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(
            to: Coordinate(latitude: 30.285167, longitude: -95.467833),
            accuracy: 1e-4
        ))
    }

    /// iOS smart punctuation rewrites straight `'` to curly `\u{2019}` in
    /// SwiftUI text fields. The parse must survive that or the Map/Convert
    /// row never appears for anything typed on-device.
    func testParseDirectionalWithCurlyApostrophes() {
        let coord = DDMConverter.parse("30 17.11\u{2019}N 095 28.07\u{2019}W")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(
            to: Coordinate(latitude: 30.285167, longitude: -95.467833),
            accuracy: 1e-4
        ))
    }

    func testFormatNorthEast() {
        let result = DDMConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertEqual(result, "41°24.2028'N, 2°10.4418'E")
    }

    func testFormatSouthWest() {
        let result = DDMConverter.format(Coordinate(latitude: -33.8688, longitude: -151.2093))
        XCTAssertEqual(result, "33°52.1280'S, 151°12.5580'W")
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = DDMConverter.format(original)
        let parsed = DDMConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-4))
    }
}
