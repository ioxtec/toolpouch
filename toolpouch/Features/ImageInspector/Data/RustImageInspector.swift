import Foundation

/// Runs image inspection and transformation on the Rust engine's actor so the
/// work never blocks the main actor.
actor RustImageInspector: ImageInspecting {
    private let engine = ToolPouchRustEngine()

    func inspectImage(at url: URL) async throws -> ImageInspection {
        do {
            let result = try await engine.inspectImage(at: url)
            return ImageInspection(
                width: result.width,
                height: result.height,
                format: result.format.title,
                colorModel: result.colorModel.title,
                channelCount: result.channelCount,
                bitsPerChannel: result.bitsPerChannel,
                hasAlpha: result.hasAlpha,
                fileSize: result.fileSize
            )
        } catch let error as ToolPouchRustEngineError {
            throw ImageInspectionError(engineError: error)
        }
    }

    func readMetadata(at url: URL) async throws -> ImageMetadata {
        do {
            let result = try await engine.readImageMetadata(at: url)
            return ImageMetadata(
                cameraMake: result.cameraMake,
                cameraModel: result.cameraModel,
                lensModel: result.lensModel,
                capturedAt: result.capturedAt,
                exposureTime: result.exposureTime,
                aperture: result.aperture,
                iso: result.iso,
                focalLength: result.focalLength,
                orientation: result.orientation,
                latitude: result.latitude,
                longitude: result.longitude
            )
        } catch let error as ToolPouchRustEngineError {
            throw ImageInspectionError(engineError: error)
        }
    }

    func transform(
        inputURL: URL,
        outputURL: URL,
        options: ImageTransformOptions
    ) async throws {
        do {
            try await engine.transformImage(
                at: inputURL,
                savingTo: outputURL,
                maximumWidth: options.maximumWidth,
                maximumHeight: options.maximumHeight,
                format: options.format.rustFormat,
                quality: options.quality
            )
        } catch let error as ToolPouchRustEngineError {
            throw ImageInspectionError(engineError: error)
        }
    }
}

nonisolated enum ImageInspectionError: LocalizedError {
    case fileUnavailable
    case unsupportedFormat
    case invalidImage
    case inspectionFailed

    init(engineError: ToolPouchRustEngineError) {
        switch engineError {
        case .fileAccessFailed:
            self = .fileUnavailable
        case .unsupportedImageFormat:
            self = .unsupportedFormat
        case .invalidImage:
            self = .invalidImage
        case .invalidArgument, .encodingFailed, .unexpectedStatus:
            self = .inspectionFailed
        }
    }

    var errorDescription: String? {
        switch self {
        case .fileUnavailable:
            "ToolPouch could not read this file."
        case .unsupportedFormat:
            "This image format is not supported yet."
        case .invalidImage:
            "The file does not contain a valid image."
        case .inspectionFailed:
            "The image could not be inspected."
        }
    }
}

private extension ImageOutputFormat {
    nonisolated var rustFormat: ToolPouchRustImageOutputFormat {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .webP: .webP
        }
    }
}

private extension ToolPouchRustImageInfo.Format {
    nonisolated var title: String {
        switch self {
        case .unknown: "Unknown"
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .gif: "GIF"
        case .webP: "WebP"
        case .tiff: "TIFF"
        case .bmp: "BMP"
        case .ico: "ICO"
        case .pnm: "PNM"
        }
    }
}

private extension ToolPouchRustImageInfo.ColorModel {
    nonisolated var title: String {
        switch self {
        case .unknown: "Unknown"
        case .grayscale: "Grayscale"
        case .grayscaleAlpha: "Grayscale + Alpha"
        case .rgb: "RGB"
        case .rgba: "RGBA"
        }
    }
}
