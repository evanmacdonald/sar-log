import Foundation

protocol CoordinateConverter {
    static func parse(_ input: String) -> Coordinate?
    static func format(_ coordinate: Coordinate) -> String
}
