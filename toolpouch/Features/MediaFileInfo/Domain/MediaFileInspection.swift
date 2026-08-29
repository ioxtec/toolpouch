import Foundation
import UniformTypeIdentifiers

nonisolated enum MediaFileKind: String, Sendable {
    case image
    case audio
    case video

    var title: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .image: "photo"
        case .audio: "waveform"
        case .video: "film"
        }
    }

    init?(contentType: UTType?, fileExtension: String) {
        if contentType?.conforms(to: .image) == true {
            self = .image
        } else if contentType?.conforms(to: .movie) == true
            || contentType?.conforms(to: .video) == true {
            self = .video
        } else if contentType?.conforms(to: .audio) == true {
            self = .audio
        } else {
            switch fileExtension.lowercased() {
            case "png", "jpg", "jpeg", "gif", "webp", "tif", "tiff", "bmp", "heic", "heif", "ico", "avif", "svg":
                self = .image
            case "mp3", "m4a", "aac", "wav", "wave", "aif", "aiff", "flac", "alac", "ogg", "opus", "caf", "mka":
                self = .audio
            case "mp4", "m4v", "mov", "avi", "mkv", "webm", "mpeg", "mpg", "ts":
                self = .video
            default:
                return nil
            }
        }
    }
}

nonisolated struct MediaTrackInspection: Identifiable, Sendable {
    let id: String
    let kind: MediaFileKind
    let codec: String
    let dimensions: String?
    let frameRate: String?
    let bitrate: String?
    let sampleRate: String?
    let channelCount: String?
    let language: String?
}

nonisolated struct MediaFileInspection: Sendable {
    let filename: String
    let kind: MediaFileKind
    let typeName: String
    let fileSize: Int64
    let createdAt: Date?
    let duration: TimeInterval?
    let dimensions: String?
    let tracks: [MediaTrackInspection]
    let waveformSamples: [Float]

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDuration: String? {
        guard let duration, duration.isFinite, duration >= 0 else { return nil }
        return Self.durationFormatter.string(from: duration)
    }

    var formattedCreationDate: String? {
        createdAt?.formatted(date: .abbreviated, time: .shortened)
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}

nonisolated enum MediaFileInspectionError: LocalizedError, Sendable {
    case unsupportedFile
    case unreadableFile
    case noMediaTracks
    case unsupportedContainer(container: String, code: Int)
    case assetReadFailed(stage: String, domain: String, code: Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "Choose an image, audio file, or video file."
        case .unreadableFile:
            "The selected file could not be read."
        case .noMediaTracks:
            "No supported media tracks were found in this file."
        case let .unsupportedContainer(container, _):
            "macOS cannot inspect this \(container) container with its built-in media framework. The file may still be valid."
        case let .assetReadFailed(stage, _, _):
            "The media framework could not read the file during \(stage)."
        }
    }

    var diagnosticSummary: String {
        switch self {
        case .unsupportedFile:
            "MediaFileInfo/unsupported-file"
        case .unreadableFile:
            "MediaFileInfo/unreadable-file"
        case .noMediaTracks:
            "MediaFileInfo/no-media-tracks"
        case let .unsupportedContainer(container, code):
            "MediaFileInfo/unsupported-container container=\(container) code=\(code)"
        case let .assetReadFailed(stage, domain, code):
            "MediaFileInfo/asset-read-failed stage=\(stage) domain=\(domain) code=\(code)"
        }
    }
}
