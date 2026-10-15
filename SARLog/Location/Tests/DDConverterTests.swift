import XCTest
@testable import SARLog

final class DDConverterTests: XCTestCase {

    func testParseValidDD() {
        let coord = DDConverter.parse("41.40338, 2.17403")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403)))
    }

    func testParseNegativeValues() {
        let coord = DDConverter.parse("-33.8688, -151.2093")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: -151.2093)))
    }

    func testParseWithoutSpaceAfterComma() {
        let coord = DDConverter.parse("41.40338,2.17403")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403)))
    }

    func testParseDirectionalNW() {
        let coord = DDConverter.parse("N 50.982646°   W 117.027118°")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 50.982646, longitude: -117.027118)))
    }

    func testParseDirectionalSE() {
        let coord = DDConverter.parse("S 33.8688° E 151.2093°")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093)))
    }

    func testParseDirectionalNoSpaces() {
        let coord = DDConverter.parse("N50.982646°W117.027118°")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 50.982646, longitude: -117.027118)))
    }

    func testParseDirectionalSuffixFormat() {
        let coord = DDConverter.parse("50.982646°N 117.027118°W")
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord!.isEqual(to: Coordinate(latitude: 50.982646, longitude: -117.027118)))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(DDConverter.parse("not a coordinate"))
        XCTAssertNil(DDConverter.parse("41.40338"))
        XCTAssertNil(DDConverter.parse(""))
    }

    func testParseOutOfRangeReturnsNil() {
        XCTAssertNil(DDConverter.parse("91.0, 0.0"))
        XCTAssertNil(DDConverter.parse("0.0, 181.0"))
    }

    func testFormatCoordinate() {
        let result = DDConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertEqual(result, "41.403380, 2.174030")
    }

    func testFormatNegativeCoordinate() {
        let result = DDConverter.format(Coordinate(latitude: -33.8688, longitude: -151.2093))
        XCTAssertEqual(result, "-33.868800, -151.209300")
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = DDConverter.format(original)
        let parsed = DDConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original))
    }
}
