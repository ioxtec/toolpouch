import UniformTypeIdentifiers

nonisolated enum ImageOutputFormat: String, CaseIterable, Identifiable, Sendable {
    case png
    case jpeg
    case webP

    var id: Self { self }

    var title: String {
        switch self {
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .webP: "WebP"
        }
    }

    var fileExtension: String { rawValue == "jpeg" ? "jpg" : rawValue.lowercased() }

    var contentType: UTType {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .webP: UTType(filenameExtension: "webp") ?? .image
        }
    }
}

nonisolated struct ImageTransformOptions: Equatable, Sendable {
    let maximumWidth: UInt32
    let maximumHeight: UInt32
    let format: ImageOutputFormat
    let quality: UInt8
}
