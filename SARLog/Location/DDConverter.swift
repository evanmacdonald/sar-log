import Foundation

enum DDConverter: CoordinateConverter {
    static func parse(_ input: String) -> Coordinate? {
        if let coord = parseDirectional(input) { return coord }
        return parseDecimal(input)
    }

    private static func parseDirectional(_ input: String) -> Coordinate? {
        let pattern = #"(?i)([NS])\s*([\d.]+)\s*°?\s*([EW])\s*([\d.]+)\s*°?|(?i)([\d.]+)\s*°?\s*([NS])\s*([\d.]+)\s*°?\s*([EW])"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        func group(_ i: Int) -> String? {
            let r = match.range(at: i)
            guard r.location != NSNotFound, let range = Range(r, in: input) else { return nil }
            return String(input[range])
        }
        let latDir: String
        let latVal: Double
        let lonDir: String
        let lonVal: Double
        if let d = group(1), !d.isEmpty {
            guard let lv = Double(group(2) ?? ""), let lnv = Double(group(4) ?? "") else { return nil }
            latDir = d; latVal = lv; lonDir = group(3) ?? "E"; lonVal = lnv
        } else {
            guard let lv = Double(group(5) ?? ""), let lnv = Double(group(7) ?? "") else { return nil }
            latVal = lv; latDir = group(6) ?? "N"; lonVal = lnv; lonDir = group(8) ?? "E"
        }
        let lat = latDir.uppercased() == "S" ? -latVal : latVal
        let lon = lonDir.uppercased() == "W" ? -lonVal : lonVal
        guard (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        return Coordinate(latitude: lat, longitude: lon)
    }

    private static func parseDecimal(_ input: String) -> Coordinate? {
        let parts = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]) else {
            return nil
        }
        guard (-90...90).contains(lat), (-180...180).contains(lon) else {
            return nil
        }
        return Coordinate(latitude: lat, longitude: lon)
    }

    static func format(_ coordinate: Coordinate) -> String {
        String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
}
