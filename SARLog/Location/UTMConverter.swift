import Foundation

enum UTMConverter: CoordinateConverter {

    static let a: Double = 6378137.0
    static let e2: Double = 0.00669437999014
    static let ePrime2: Double = 0.00673949674228
    static let k0: Double = 0.9996

    private static let utmLetters = "CDEFGHJKLMNPQRSTUVWX"

    static func parse(_ input: String) -> Coordinate? {
        let pattern = #"(\d{1,2})\s*([A-Za-z])\s+(\d+)\s+(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        func group(_ i: Int) -> String {
            let range = Range(match.range(at: i), in: input)!
            return String(input[range])
        }

        guard let zone = Int(group(1)),
              (1...60).contains(zone) else {
            return nil
        }

        let letter = group(2).uppercased().first!
        guard utmLetters.contains(letter) else {
            return nil
        }

        guard let easting = Double(group(3)),
              let northing = Double(group(4)) else {
            return nil
        }

        let isNorthern = letter >= "N"
        return utmToLatLon(zone: zone, easting: easting, northing: northing, northern: isNorthern)
    }

    static func format(_ coordinate: Coordinate) -> String {
        let (zone, letter, easting, northing) = latLonToUTM(lat: coordinate.latitude, lon: coordinate.longitude)
        return "\(zone)\(letter) \(Int(easting.rounded())) \(Int(northing.rounded()))"
    }

    static func latLonToUTM(lat: Double, lon: Double) -> (zone: Int, letter: Character, easting: Double, northing: Double) {
        let latRad = lat * .pi / 180.0
        let lonRad = lon * .pi / 180.0

        let zone = utmZone(lon: lon)
        let lonOrigin = Double((zone - 1) * 6 - 180 + 3)
        let lonOriginRad = lonOrigin * .pi / 180.0

        let N = a / sqrt(1 - e2 * sin(latRad) * sin(latRad))
        let T = tan(latRad) * tan(latRad)
        let C = ePrime2 * cos(latRad) * cos(latRad)
        let A = cos(latRad) * (lonRad - lonOriginRad)
        let M = meridianArc(latRad: latRad)

        let easting = k0 * N * (A + (1 - T + C) * A * A * A / 6
            + (5 - 18 * T + T * T + 72 * C - 58 * ePrime2) * pow(A, 5) / 120) + 500000.0

        var northing = k0 * (M + N * tan(latRad) * (A * A / 2
            + (5 - T + 9 * C + 4 * C * C) * pow(A, 4) / 24
            + (61 - 58 * T + T * T + 600 * C - 330 * ePrime2) * pow(A, 6) / 720))

        if lat < 0 {
            northing += 10000000.0
        }

        let letter = utmLetter(lat: lat)

        return (zone, letter, easting, northing)
    }

    private static func utmToLatLon(zone: Int, easting: Double, northing: Double, northern: Bool) -> Coordinate {
        let x = easting - 500000.0
        var y = northing
        if !northern {
            y -= 10000000.0
        }

        let lonOrigin = Double((zone - 1) * 6 - 180 + 3)

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

    static func meridianArc(latRad: Double) -> Double {
        a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * latRad
            - (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * sin(2 * latRad)
            + (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * sin(4 * latRad)
            - (35 * e2 * e2 * e2 / 3072) * sin(6 * latRad))
    }

    static func utmZone(lon: Double) -> Int {
        // Longitude 180° would produce zone 61 by the naïve formula; UTM
        // zones are defined for 1…60, so clamp the antimeridian back to 60.
        let raw = Int((lon + 180) / 6) + 1
        return min(max(raw, 1), 60)
    }

    static func utmLetter(lat: Double) -> Character {
        let letters = Array(utmLetters)
        if lat < -80 { return "C" }
        if lat >= 84 { return "X" }
        let index = Int((lat + 80) / 8)
        return letters[min(index, letters.count - 1)]
    }
}
