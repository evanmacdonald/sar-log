import Foundation

/// Open Location Code "pairs" encoding for 10-digit full codes.
/// Each pair uses the same resolution for lat and lon (OLC subdivides each
/// cell into a 20x20 grid at every level), not asymmetric lat/lon ratios.
/// Grid refinement for 11+ digit codes isn't needed for standard shareable
/// Plus Codes.
enum PlusCodeConverter: CoordinateConverter {

    private static let alphabet = Array("23456789CFGHJMPQRVWX")
    private static let base = 20
    private static let separator: Character = "+"
    private static let separatorPosition = 8
    private static let latitudeMax = 90.0
    private static let longitudeMax = 180.0

    /// Degree size of a pair at each level: start with 20° (world/20),
    /// divide by 20 each time.
    private static let pairResolutions: [Double] = [20.0, 1.0, 0.05, 0.0025, 0.000125]

    static func parse(_ input: String) -> Coordinate? {
        let trimmed = input.trimmingCharacters(in: .whitespaces).uppercased()

        guard let plusIndex = trimmed.firstIndex(of: separator) else {
            return nil
        }

        let charsBeforePlus = trimmed.distance(from: trimmed.startIndex, to: plusIndex)
        guard charsBeforePlus == separatorPosition else {
            return nil
        }

        let code = trimmed.replacingOccurrences(of: String(separator), with: "")

        guard code.count >= 8, code.count % 2 == 0 else {
            return nil
        }

        let chars = Array(code)
        let charSet = Set(alphabet)
        for ch in chars {
            guard charSet.contains(ch) else { return nil }
        }

        var latitude = 0.0
        var longitude = 0.0
        let pairCount = min(chars.count / 2, pairResolutions.count)

        for i in 0..<pairCount {
            guard let latIdx = alphabet.firstIndex(of: chars[i * 2]),
                  let lonIdx = alphabet.firstIndex(of: chars[i * 2 + 1]) else {
                return nil
            }
            latitude += Double(latIdx) * pairResolutions[i]
            longitude += Double(lonIdx) * pairResolutions[i]
        }

        let lastRes = pairResolutions[pairCount - 1]
        latitude += lastRes / 2.0
        longitude += lastRes / 2.0

        latitude -= latitudeMax
        longitude -= longitudeMax

        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            return nil
        }

        return Coordinate(latitude: latitude, longitude: longitude)
    }

    static func format(_ coordinate: Coordinate) -> String {
        var lat = min(max(coordinate.latitude, -latitudeMax), latitudeMax - pairResolutions[pairResolutions.count - 1])
        var lon = coordinate.longitude
        while lon < -longitudeMax { lon += 360.0 }
        while lon >= longitudeMax { lon -= 360.0 }

        lat += latitudeMax
        lon += longitudeMax

        var code = ""
        for i in 0..<pairResolutions.count {
            let latDigit = min(Int(lat / pairResolutions[i]), base - 1)
            let lonDigit = min(Int(lon / pairResolutions[i]), base - 1)
            lat -= Double(latDigit) * pairResolutions[i]
            lon -= Double(lonDigit) * pairResolutions[i]
            code.append(alphabet[latDigit])
            code.append(alphabet[lonDigit])
            if i == 3 {
                code.append(separator)
            }
        }

        return code
    }
}
