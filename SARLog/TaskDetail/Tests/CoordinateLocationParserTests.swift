import XCTest
@testable import SARLog

final class CoordinateLocationParserTests: XCTestCase {
    func testParsesDecimalLatitudeLongitude() {
        let coordinate = CoordinateLocationParser.coordinate(from: "49.123, -123.456")

        XCTAssertEqual(coordinate?.latitude, 49.123)
        XCTAssertEqual(coordinate?.longitude, -123.456)
    }

    func testRejectsNonCoordinateLocationText() {
        XCTAssertNil(CoordinateLocationParser.coordinate(from: "Trailhead by the bridge"))
        XCTAssertNil(CoordinateLocationParser.coordinate(from: "49.123"))
        XCTAssertNil(CoordinateLocationParser.coordinate(from: "49.123, -123.456, 7"))
    }

    func testRejectsOutOfRangeCoordinates() {
        XCTAssertNil(CoordinateLocationParser.coordinate(from: "91, -123.456"))
        XCTAssertNil(CoordinateLocationParser.coordinate(from: "49.123, -181"))
    }

    func testBuildsAppleMapsURLForCoordinates() throws {
        let url = try XCTUnwrap(CoordinateLocationParser.appleMapsURL(for: "49.123, -123.456"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "http")
        XCTAssertEqual(components.host, "maps.apple.com")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "ll" })?.value, "49.123,-123.456")
    }
}
