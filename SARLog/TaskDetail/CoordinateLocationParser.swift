import Foundation

struct CoordinateLocationParser {
    struct Coordinate: Equatable {
        let latitude: Double
        let longitude: Double
    }

    static func coordinate(from value: String) -> Coordinate? {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ",", omittingEmptySubsequences: false)

        guard parts.count == 2 else {
            return nil
        }

        let latitudeText = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let longitudeText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let latitude = Double(latitudeText),
            let longitude = Double(longitudeText),
            (-90...90).contains(latitude),
            (-180...180).contains(longitude)
        else {
            return nil
        }

        return Coordinate(latitude: latitude, longitude: longitude)
    }

    static func appleMapsURL(for value: String) -> URL? {
        guard let coordinate = coordinate(from: value) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "http"
        components.host = "maps.apple.com"
        components.path = "/"
        components.queryItems = [
            URLQueryItem(
                name: "ll",
                value: "\(coordinate.latitude),\(coordinate.longitude)"
            )
        ]
        return components.url
    }
}
