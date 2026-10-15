import Foundation

enum DDMConverter: CoordinateConverter {
    static func parse(_ input: String) -> Coordinate? {
        if let result = parseStandard(input) { return result }
        return parseLenient(input)
    }

    private static func parseStandard(_ input: String) -> Coordinate? {
        let pattern = #"(\d+)\s*°\s*(\d+\.?\d*)\s*'\s*([NSns])\s*,\s*(\d+)\s*°\s*(\d+\.?\d*)\s*'\s*([EWew])"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        func group(_ i: Int) -> String {
            let range = Range(match.range(at: i), in: input)!
            return String(input[range])
        }

        guard let latDeg = Double(group(1)),
              let latMin = Double(group(2)),
              let lonDeg = Double(group(4)),
              let lonMin = Double(group(5)) else {
            return nil
        }

        var lat = latDeg + latMin / 60.0
        var lon = lonDeg + lonMin / 60.0

        if group(3).uppercased() == "S" { lat = -lat }
        if group(6).uppercased() == "W" { lon = -lon }

        guard (-90...90).contains(lat), (-180...180).contains(lon) else {
            return nil
        }

        return Coordinate(latitude: lat, longitude: lon)
    }

    private static func parseLenient(_ input: String) -> Coordinate? {
        let pattern = #"(-?\d+)\s+(\d+\.?\d*)\s*,\s*(-?\d+)\s+(\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        func group(_ i: Int) -> String {
            let range = Range(match.range(at: i), in: input)!
            return String(input[range])
        }

        guard let latDegSigned = Double(group(1)),
              let latMin = Double(group(2)),
              let lonDegSigned = Double(group(3)),
              let lonMin = Double(group(4)) else {
            return nil
        }

        let latSign: Double = latDegSigned < 0 ? -1 : 1
        let lonSign: Double = lonDegSigned < 0 ? -1 : 1

        let lat = latSign * (abs(latDegSigned) + latMin / 60.0)
        let lon = lonSign * (abs(lonDegSigned) + lonMin / 60.0)

        guard (-90...90).contains(lat), (-180...180).contains(lon) else {
            return nil
        }

        return Coordinate(latitude: lat, longitude: lon)
    }

    static func format(_ coordinate: Coordinate) -> String {
        let latDir = coordinate.latitude >= 0 ? "N" : "S"
        let lonDir = coordinate.longitude >= 0 ? "E" : "W"

        let absLat = abs(coordinate.latitude)
        let absLon = abs(coordinate.longitude)

        let latDeg = Int(absLat)
        let latMin = (absLat - Double(latDeg)) * 60.0

        let lonDeg = Int(absLon)
        let lonMin = (absLon - Double(lonDeg)) * 60.0

        return String(format: "%d°%.4f'%@, %d°%.4f'%@",
                       latDeg, latMin, latDir,
                       lonDeg, lonMin, lonDir)
    }
}
