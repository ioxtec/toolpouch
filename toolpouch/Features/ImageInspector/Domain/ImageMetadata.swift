import Foundation

nonisolated struct ImageMetadata: Equatable, Sendable {
    let cameraMake: String?
    let cameraModel: String?
    let lensModel: String?
    let capturedAt: String?
    let exposureTime: String?
    let aperture: String?
    let iso: String?
    let focalLength: String?
    let orientation: String?
    let latitude: Double?
    let longitude: Double?

    var hasExifValues: Bool {
        [cameraMake, cameraModel, lensModel, capturedAt, exposureTime,
         aperture, iso, focalLength, orientation].contains { $0 != nil }
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var coordinateText: String? {
        guard let latitude, let longitude else { return nil }
        return String(
            format: "%.6f, %.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            latitude,
            longitude
        )
    }

    var mapURL: URL? {
        guard let coordinateText else { return nil }
        return URL(string: "https://maps.apple.com/?ll=\(coordinateText.replacingOccurrences(of: " ", with: ""))")
    }
}
