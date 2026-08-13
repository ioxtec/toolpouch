import CoreLocation
import Foundation

/// A platform-independent coordinate used by the formatter and the map UI.
/// Keeping this value separate from MapKit makes conversions easy to test and reuse.
nonisolated struct GeographicCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    var coreLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated enum CoordinateDisplayFormat: String, CaseIterable, Identifiable, Sendable {
    case decimalDegrees
    case degreesDecimalMinutes
    case degreesMinutesSeconds
    case geoURI

    var id: Self { self }

    var title: String {
        switch self {
        case .decimalDegrees: "Decimal degrees (DD)"
        case .degreesDecimalMinutes: "Degrees and minutes (DDM)"
        case .degreesMinutesSeconds: "Degrees, minutes and seconds (DMS)"
        case .geoURI: "Geo URI"
        }
    }

    func string(for coordinate: GeographicCoordinate) -> String {
        switch self {
        case .decimalDegrees:
            return "\(fixed(coordinate.latitude, precision: 6)), \(fixed(coordinate.longitude, precision: 6))"
        case .degreesDecimalMinutes:
            return "\(ddm(coordinate.latitude, positive: "N", negative: "S")), "
                + "\(ddm(coordinate.longitude, positive: "E", negative: "W"))"
        case .degreesMinutesSeconds:
            return "\(dms(coordinate.latitude, positive: "N", negative: "S")), "
                + "\(dms(coordinate.longitude, positive: "E", negative: "W"))"
        case .geoURI:
            return "geo:\(fixed(coordinate.latitude, precision: 6)),\(fixed(coordinate.longitude, precision: 6))"
        }
    }

    private func ddm(_ value: Double, positive: String, negative: String) -> String {
        let absolute = abs(value)
        let degrees = Int(absolute)
        let minutes = (absolute - Double(degrees)) * 60
        return "\(degrees)° \(fixed(minutes, precision: 5))′ \(value < 0 ? negative : positive)"
    }

    private func dms(_ value: Double, positive: String, negative: String) -> String {
        let absolute = abs(value)
        let degrees = Int(absolute)
        let totalMinutes = (absolute - Double(degrees)) * 60
        let minutes = Int(totalMinutes)
        let seconds = (totalMinutes - Double(minutes)) * 60
        return "\(degrees)° \(minutes)′ \(fixed(seconds, precision: 3))″ \(value < 0 ? negative : positive)"
    }

    private func fixed(_ value: Double, precision: Int) -> String {
        String(format: "%.*f", locale: Locale(identifier: "en_US_POSIX"), precision, value)
    }
}
