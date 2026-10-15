import Foundation

enum MGRSConverter: CoordinateConverter {

    private static let columnLettersSets: [[Character]] = [
        Array("ABCDEFGH"),
        Array("JKLMNPQR"),
        Array("STUVWXYZ"),
    ]

    private static let rowLettersOdd  = Array("ABCDEFGHJKLMNPQRSTUV")
    private static let rowLettersEven = Array("FGHJKLMNPQRSTUVABCDE")

    private static let bandLetters = "CDEFGHJKLMNPQRSTUVWX"

    static func parse(_ input: String) -> Coordinate? {
        let cleaned = input.uppercased().replacingOccurrences(of: " ", with: "")

        let pattern = #"^(\d{1,2})([A-Z])([A-Z])([A-Z])(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) else {
            return nil
        }

        func group(_ i: Int) -> String {
            let range = Range(match.range(at: i), in: cleaned)!
            return String(cleaned[range])
        }

        guard let zone = Int(group(1)),
              (1...60).contains(zone) else {
            return nil
        }

        let bandLetter = group(2).first!
        guard bandLetters.contains(bandLetter) else { return nil }

        let colLetter = group(3).first!
        let rowLetter = group(4).first!
        let digits = group(5)

        guard digits.count % 2 == 0, digits.count >= 2 else { return nil }

        let precision = digits.count / 2
        let eastDigits = String(digits.prefix(precision))
        let northDigits = String(digits.suffix(precision))

        guard var eastingInSquare = Double(eastDigits),
              var northingInSquare = Double(northDigits) else {
            return nil
        }

        let scale = pow(10.0, Double(5 - precision))
        eastingInSquare *= scale
        northingInSquare *= scale

        let setIndex = (zone - 1) % 3
        let colLetters = columnLettersSets[setIndex]
        guard let colIndex = colLetters.firstIndex(of: colLetter) else { return nil }
        let easting100k = Double(colIndex + 1) * 100000.0

        let rowLetters = (zone % 2 == 1) ? rowLettersOdd : rowLettersEven
        guard let rowIndex = rowLetters.firstIndex(of: rowLetter) else { return nil }
        let northingInCycle = Double(rowIndex) * 100000.0

        let isNorthern = bandLetter >= "N"
        let midLat = bandMidLatitude(bandLetter)
        let midLatRad = midLat * .pi / 180.0
        var expectedNorthing = UTMConverter.meridianArc(latRad: midLatRad)
        if !isNorthern {
            expectedNorthing += 10000000.0
        }

        let cycleCount = round((expectedNorthing - northingInCycle) / 2000000.0)
        let fullNorthing = cycleCount * 2000000.0 + northingInCycle + northingInSquare

        let fullEasting = easting100k + eastingInSquare

        return utmToLatLon(zone: zone, easting: fullEasting, northing: fullNorthing, northern: isNorthern)
    }

    static func format(_ coordinate: Coordinate) -> String {
        let (zone, letter, easting, northing) = UTMConverter.latLonToUTM(lat: coordinate.latitude, lon: coordinate.longitude)

        let setIndex = (zone - 1) % 3
        let colLetters = columnLettersSets[setIndex]
        let col100k = Int(easting / 100000.0)
        let colLetter = colLetters[col100k - 1]

        let rowLetters = (zone % 2 == 1) ? rowLettersOdd : rowLettersEven
        let row100k = Int(northing.truncatingRemainder(dividingBy: 2000000.0) / 100000.0)
        let rowLetter = rowLetters[row100k]

        let eastInSquare = Int(easting.truncatingRemainder(dividingBy: 100000.0))
        let northInSquare = Int(northing.truncatingRemainder(dividingBy: 100000.0))

        return "\(zone)\(letter)\(colLetter)\(rowLetter)\(String(format: "%05d%05d", eastInSquare, northInSquare))"
    }

    private static func bandMidLatitude(_ band: Character) -> Double {
        guard let idx = bandLetters.firstIndex(of: band) else { return 0 }
        let i = bandLetters.distance(from: bandLetters.startIndex, to: idx)
        if band == "X" { return 78.0 }
        return -76.0 + Double(i) * 8.0
    }

    private static func utmToLatLon(zone: Int, easting: Double, northing: Double, northern: Bool) -> Coordinate {
        let x = easting - 500000.0
        var y = northing
        if !northern {
            y -= 10000000.0
        }

        let lonOrigin = Double((zone - 1) * 6 - 180 + 3)

        let a = UTMConverter.a
        let e2 = UTMConverter.e2
        let ePrime2 = UTMConverter.ePrime2
        let k0 = UTMConverter.k0

        let M = y / k0
        let mu = M / (a * (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256))

        let e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
        let phi1 = mu + (3 * e1 / 2 - 27 * pow(e1, 3) / 32) * sin(2 * mu)
            + (21 * e1 * e1 / 16 - 55 * pow(e1, 4) / 32) * sin(4 * mu)
            + (151 * pow(e1, 3) / 96) * sin(6 * mu)
            + (1097 * pow(e1, 4) / 512) * sin(8 * mu)

        let N1 = a / sqrt(1 - e2 * sin(phi1) * sin(phi1))
        let T1 = tan(phi1) * tan(phi1)
        let C1 = ePrime2 * cos(phi1) * cos(phi1)
        let R1 = a * (1 - e2) / pow(1 - e2 * sin(phi1) * sin(phi1), 1.5)
        let D = x / (N1 * k0)

        let lat = phi1 - (N1 * tan(phi1) / R1) * (D * D / 2
            - (5 + 3 * T1 + 10 * C1 - 4 * C1 * C1 - 9 * ePrime2) * pow(D, 4) / 24
            + (61 + 90 * T1 + 298 * C1 + 45 * T1 * T1 - 252 * ePrime2 - 3 * C1 * C1) * pow(D, 6) / 720)

        let lon = (D - (1 + 2 * T1 + C1) * pow(D, 3) / 6
            + (5 - 2 * C1 + 28 * T1 - 3 * C1 * C1 + 8 * ePrime2 + 24 * T1 * T1) * pow(D, 5) / 120) / cos(phi1)

        let latDeg = lat * 180.0 / .pi
        let lonDeg = lonOrigin + lon * 180.0 / .pi

        return Coordinate(latitude: latDeg, longitude: lonDeg)
    }
}
