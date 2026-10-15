import XCTest
@testable import SARLog

final class PlusCodeConverterTests: XCTestCase {

    func testFormatOrigin() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 0.0, longitude: 0.0))
        XCTAssertTrue(result.contains("+"))
        let plusIndex = result.firstIndex(of: "+")!
        XCTAssertEqual(result.distance(from: result.startIndex, to: plusIndex), 8)
    }

    func testFormatProduces10DigitCode() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        let digits = result.replacingOccurrences(of: "+", with: "")
        XCTAssertEqual(digits.count, 10)
    }

    func testFormatNorthernHemisphere() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 41.40338, longitude: 2.17403))
        XCTAssertTrue(result.contains("+"))
        let parsed = PlusCodeConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: 41.40338, longitude: 2.17403), accuracy: 1e-3))
    }

    func testFormatSouthernHemisphere() {
        let result = PlusCodeConverter.format(Coordinate(latitude: -33.8688, longitude: 151.2093))
        let parsed = PlusCodeConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: -33.8688, longitude: 151.2093), accuracy: 1e-3))
    }

    func testFormatWesternHemisphere() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 40.7128, longitude: -74.0060))
        let parsed = PlusCodeConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: 40.7128, longitude: -74.0060), accuracy: 1e-3))
    }

    func testFormatSouthWestHemisphere() {
        let result = PlusCodeConverter.format(Coordinate(latitude: -34.6037, longitude: -58.3816))
        let parsed = PlusCodeConverter.parse(result)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: Coordinate(latitude: -34.6037, longitude: -58.3816), accuracy: 1e-3))
    }

    func testFormatOnlyContainsValidCharacters() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 37.422, longitude: -122.084))
        let validChars = Set("23456789CFGHJMPQRVWX+")
        for char in result {
            XCTAssertTrue(validChars.contains(char), "Invalid character '\(char)' in Plus Code: \(result)")
        }
    }

    func testFormatClampsLatitude() {
        let result = PlusCodeConverter.format(Coordinate(latitude: 90.0, longitude: 0.0))
        XCTAssertTrue(result.contains("+"))
        let parsed = PlusCodeConverter.parse(result)
        XCTAssertNotNil(parsed)
    }

    func testParseValidFullCode() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let code = PlusCodeConverter.format(original)
        let parsed = PlusCodeConverter.parse(code)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    /// A well-known Plus Code must decode to its real-world location, not an
    /// internally-consistent-but-arbitrary round-trip point. Googleplex is
    /// the OLC spec's canonical example.
    func testParseGoogleplexPlusCode() {
        let parsed = PlusCodeConverter.parse("849VCWC8+R9")
        XCTAssertNotNil(parsed)
        XCTAssertTrue(
            parsed!.isEqual(
                to: Coordinate(latitude: 37.4221, longitude: -122.0841),
                accuracy: 1e-3
            ),
            "Expected Googleplex (~37.4221, -122.0841), got (\(parsed!.latitude), \(parsed!.longitude))"
        )
    }

    func testFormatGoogleplexMatchesSpec() {
        let formatted = PlusCodeConverter.format(Coordinate(latitude: 37.4221, longitude: -122.0841))
        XCTAssertEqual(formatted, "849VCWC8+R9")
    }

    func testParseLowercaseInput() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let code = PlusCodeConverter.format(original).lowercased()
        let parsed = PlusCodeConverter.parse(code)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testParseMinimalFullCode() {
        let original = Coordinate(latitude: 20.0, longitude: 30.0)
        let fullCode = PlusCodeConverter.format(original)
        let eightDigitCode = String(fullCode.prefix(9))
        let parsed = PlusCodeConverter.parse(eightDigitCode)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 0.02))
    }

    func testParseMalformedReturnsNil() {
        XCTAssertNil(PlusCodeConverter.parse("not a code"))
        XCTAssertNil(PlusCodeConverter.parse(""))
        XCTAssertNil(PlusCodeConverter.parse("12345678"))
        XCTAssertNil(PlusCodeConverter.parse("1234+5678"))
        XCTAssertNil(PlusCodeConverter.parse("ABCD1234+56"))
    }

    func testParseOddLengthBeforePlusReturnsNil() {
        XCTAssertNil(PlusCodeConverter.parse("2345678+90"))
    }

    func testParseTooShortReturnsNil() {
        XCTAssertNil(PlusCodeConverter.parse("234567+89"))
    }

    func testRoundTrip() {
        let original = Coordinate(latitude: 41.40338, longitude: 2.17403)
        let formatted = PlusCodeConverter.format(original)
        let parsed = PlusCodeConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testRoundTripNegativeCoordinates() {
        let original = Coordinate(latitude: -33.8688, longitude: -151.2093)
        let formatted = PlusCodeConverter.format(original)
        let parsed = PlusCodeConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3))
    }

    func testRoundTripNearPoles() {
        let arctic = Coordinate(latitude: 89.0, longitude: 0.0)
        let formatted = PlusCodeConverter.format(arctic)
        let parsed = PlusCodeConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: arctic, accuracy: 1e-3))

        let antarctic = Coordinate(latitude: -89.0, longitude: 0.0)
        let formatted2 = PlusCodeConverter.format(antarctic)
        let parsed2 = PlusCodeConverter.parse(formatted2)
        XCTAssertNotNil(parsed2)
        XCTAssertTrue(parsed2!.isEqual(to: antarctic, accuracy: 1e-3))
    }

    func testRoundTripNearDateLine() {
        let east = Coordinate(latitude: 0.0, longitude: 179.0)
        let formatted = PlusCodeConverter.format(east)
        let parsed = PlusCodeConverter.parse(formatted)
        XCTAssertNotNil(parsed)
        XCTAssertTrue(parsed!.isEqual(to: east, accuracy: 1e-3))

        let west = Coordinate(latitude: 0.0, longitude: -179.0)
        let formatted2 = PlusCodeConverter.format(west)
        let parsed2 = PlusCodeConverter.parse(formatted2)
        XCTAssertNotNil(parsed2)
        XCTAssertTrue(parsed2!.isEqual(to: west, accuracy: 1e-3))
    }

    func testRoundTripMultipleLocations() {
        let locations: [(Double, Double)] = [
            (48.8566, 2.3522),
            (35.6762, 139.6503),
            (-22.9068, -43.1729),
            (55.7558, 37.6173),
            (1.3521, 103.8198),
        ]
        for (lat, lon) in locations {
            let original = Coordinate(latitude: lat, longitude: lon)
            let formatted = PlusCodeConverter.format(original)
            let parsed = PlusCodeConverter.parse(formatted)
            XCTAssertNotNil(parsed, "Failed to parse Plus Code for (\(lat), \(lon)): \(formatted)")
            XCTAssertTrue(parsed!.isEqual(to: original, accuracy: 1e-3),
                          "Round-trip failed for (\(lat), \(lon)): got (\(parsed!.latitude), \(parsed!.longitude))")
        }
    }
}
