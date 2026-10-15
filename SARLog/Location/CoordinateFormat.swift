import Foundation

enum CoordinateFormat: String, CaseIterable, Identifiable {
    case dd = "DD"
    case ddm = "DDM"
    case dms = "DMS"
    case utm = "UTM"
    case mgrs = "MGRS"
    case plusCode = "Plus Code"

    var id: String { rawValue }

    var converter: any CoordinateConverter.Type {
        switch self {
        case .dd: DDConverter.self
        case .ddm: DDMConverter.self
        case .dms: DMSConverter.self
        case .utm: UTMConverter.self
        case .mgrs: MGRSConverter.self
        case .plusCode: PlusCodeConverter.self
        }
    }

    static func detect(_ input: String) -> CoordinateFormat? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if PlusCodeConverter.parse(trimmed) != nil { return .plusCode }
        if MGRSConverter.parse(trimmed) != nil { return .mgrs }
        if UTMConverter.parse(trimmed) != nil { return .utm }
        if DMSConverter.parse(trimmed) != nil { return .dms }
        if DDMConverter.parse(trimmed) != nil { return .ddm }
        if DDConverter.parse(trimmed) != nil { return .dd }

        return nil
    }
}
