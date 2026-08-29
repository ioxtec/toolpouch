import AVFoundation
import CoreMedia
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

actor AVFoundationMediaFileInspector: MediaFileInspecting {
    private let waveformPointCount = 120
    private nonisolated static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.hoxim.toolpouch",
        category: "MediaFileInfo"
    )

    func inspectMedia(at url: URL) async throws -> MediaFileInspection {
        let values = try url.resourceValues(forKeys: [
            .creationDateKey,
            .fileSizeKey,
            .nameKey,
        ])
        let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)
            ?? UTType(filenameExtension: url.pathExtension)
        guard let kind = MediaFileKind(
            contentType: contentType,
            fileExtension: url.pathExtension
        ) else {
            throw MediaFileInspectionError.unsupportedFile
        }

        let common = CommonFileValues(
            filename: values.name ?? url.lastPathComponent,
            typeName: contentType?.localizedDescription
                ?? contentType?.identifier
                ?? url.pathExtension.uppercased(),
            fileSize: Int64(values.fileSize ?? 0),
            createdAt: values.creationDate
        )

        Self.logger.info(
            "Inspection started kind=\(kind.rawValue, privacy: .public) extension=\(url.pathExtension.lowercased(), privacy: .public) bytes=\(common.fileSize)"
        )

        do {
            let inspection = switch kind {
            case .image:
                try inspectImage(at: url, common: common)
            case .audio, .video:
                try await inspectAsset(at: url, kind: kind, common: common)
            }
            Self.logger.info(
                "Inspection completed kind=\(kind.rawValue, privacy: .public) tracks=\(inspection.tracks.count) waveformPoints=\(inspection.waveformSamples.count)"
            )
            return inspection
        } catch {
            let failure = error as NSError
            Self.logger.error(
                "Inspection failed kind=\(kind.rawValue, privacy: .public) extension=\(url.pathExtension.lowercased(), privacy: .public) domain=\(failure.domain, privacy: .public) code=\(failure.code)"
            )
            throw error
        }
    }

    private func inspectImage(
        at url: URL,
        common: CommonFileValues
    ) throws -> MediaFileInspection {
        if url.pathExtension.lowercased() == "svg" {
            return MediaFileInspection(
                filename: common.filename,
                kind: .image,
                typeName: common.typeName,
                fileSize: common.fileSize,
                createdAt: common.createdAt,
                duration: nil,
                dimensions: try SVGMetadataParser().dimensions(at: url),
                tracks: [],
                waveformSamples: []
            )
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any] else {
            throw MediaFileInspectionError.unreadableFile
        }

        let width = properties[kCGImagePropertyPixelWidth] as? Int
        let height = properties[kCGImagePropertyPixelHeight] as? Int
        let dimensions = width.flatMap { width in
            height.map { "\(width) × \($0) px" }
        }

        return MediaFileInspection(
            filename: common.filename,
            kind: .image,
            typeName: common.typeName,
            fileSize: common.fileSize,
            createdAt: common.createdAt,
            duration: nil,
            dimensions: dimensions,
            tracks: [],
            waveformSamples: []
        )
    }

    private func inspectAsset(
        at url: URL,
        kind: MediaFileKind,
        common: CommonFileValues
    ) async throws -> MediaFileInspection {
        if ["mkv", "webm", "mka"].contains(url.pathExtension.lowercased()) {
            do {
                let metadata = try MatroskaMetadataParser().parse(url: url)
                Self.logger.info(
                    "Matroska fallback completed tracks=\(metadata.tracks.count)"
                )
                return MediaFileInspection(
                    filename: common.filename,
                    kind: kind,
                    typeName: common.typeName,
                    fileSize: common.fileSize,
                    createdAt: common.createdAt,
                    duration: metadata.duration,
                    dimensions: metadata.dimensions,
                    tracks: metadata.tracks,
                    waveformSamples: []
                )
            } catch {
                Self.logRecoverable(error, stage: "matroska-container")
            }
        }

        let asset = AVURLAsset(url: url)
        let duration: TimeInterval?
        do {
            let loadedDuration = try await asset.load(.duration).seconds
            duration = loadedDuration.isFinite ? loadedDuration : nil
        } catch {
            duration = nil
            Self.logRecoverable(error, stage: "duration")
        }

        var loadingErrors: [(stage: String, error: NSError)] = []
        let videoTracks: [AVAssetTrack]
        do {
            videoTracks = try await asset.loadTracks(withMediaType: .video)
        } catch {
            videoTracks = []
            loadingErrors.append(("video tracks", error as NSError))
            Self.logRecoverable(error, stage: "video-tracks")
        }

        let audioTracks: [AVAssetTrack]
        do {
            audioTracks = try await asset.loadTracks(withMediaType: .audio)
        } catch {
            audioTracks = []
            loadingErrors.append(("audio tracks", error as NSError))
            Self.logRecoverable(error, stage: "audio-tracks")
        }

        guard !videoTracks.isEmpty || !audioTracks.isEmpty else {
            if let failure = loadingErrors.first {
                if url.pathExtension.lowercased() == "mkv" {
                    throw MediaFileInspectionError.unsupportedContainer(
                        container: "MKV",
                        code: failure.error.code
                    )
                }
                throw MediaFileInspectionError.assetReadFailed(
                    stage: failure.stage,
                    domain: failure.error.domain,
                    code: failure.error.code
                )
            }
            throw MediaFileInspectionError.noMediaTracks
        }

        var tracks: [MediaTrackInspection] = []
        for (index, track) in videoTracks.enumerated() {
            tracks.append(await inspectVideoTrack(track, index: index))
        }
        for (index, track) in audioTracks.enumerated() {
            tracks.append(await inspectAudioTrack(track, index: index))
        }

        let dimensions: String?
        if let track = videoTracks.first {
            dimensions = await displaySize(for: track).flatMap(Self.formatDimensions)
        } else {
            dimensions = nil
        }
        let waveform: [Float]
        if kind == .audio {
            do {
                waveform = try makeWaveform(at: url, pointCount: waveformPointCount)
            } catch {
                Self.logRecoverable(error, stage: "waveform")
                waveform = []
            }
        } else {
            waveform = []
        }

        return MediaFileInspection(
            filename: common.filename,
            kind: kind,
            typeName: common.typeName,
            fileSize: common.fileSize,
            createdAt: common.createdAt,
            duration: duration,
            dimensions: dimensions,
            tracks: tracks,
            waveformSamples: waveform
        )
    }

    private func inspectVideoTrack(
        _ track: AVAssetTrack,
        index: Int
    ) async -> MediaTrackInspection {
        let formatDescriptions = (try? await track.load(.formatDescriptions)) ?? []
        let size = await displaySize(for: track)
        let frameRate = try? await track.load(.nominalFrameRate)
        let bitrate = try? await track.load(.estimatedDataRate)
        let language = try? await track.load(.languageCode)

        return MediaTrackInspection(
            id: "video-\(index)",
            kind: .video,
            codec: Self.codecName(from: formatDescriptions.first),
            dimensions: size.flatMap(Self.formatDimensions),
            frameRate: frameRate.flatMap {
                $0 > 0 ? "\($0.formatted(.number.precision(.fractionLength(0...2)))) fps" : nil
            },
            bitrate: bitrate.flatMap(Self.formatBitrate),
            sampleRate: nil,
            channelCount: nil,
            language: language
        )
    }

    private func inspectAudioTrack(
        _ track: AVAssetTrack,
        index: Int
    ) async -> MediaTrackInspection {
        let formatDescriptions = (try? await track.load(.formatDescriptions)) ?? []
        let bitrate = try? await track.load(.estimatedDataRate)
        let language = try? await track.load(.languageCode)
        let audioDescription = formatDescriptions.first.flatMap {
            CMAudioFormatDescriptionGetStreamBasicDescription($0)
        }

        return MediaTrackInspection(
            id: "audio-\(index)",
            kind: .audio,
            codec: Self.codecName(from: formatDescriptions.first),
            dimensions: nil,
            frameRate: nil,
            bitrate: bitrate.flatMap(Self.formatBitrate),
            sampleRate: audioDescription.map {
                "\(Int($0.pointee.mSampleRate.rounded()).formatted()) Hz"
            },
            channelCount: audioDescription.map {
                let count = Int($0.pointee.mChannelsPerFrame)
                return count == 1 ? "Mono" : count == 2 ? "Stereo" : "\(count) channels"
            },
            language: language
        )
    }

    private func displaySize(for track: AVAssetTrack) async -> CGSize? {
        guard let naturalSize = try? await track.load(.naturalSize),
              let transform = try? await track.load(.preferredTransform) else {
            return nil
        }
        let transformed = naturalSize.applying(transform)
        return CGSize(width: abs(transformed.width), height: abs(transformed.height))
    }

    private func makeWaveform(at url: URL, pointCount: Int) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let totalFrames = max(1, file.length)
        let format = file.processingFormat
        guard format.channelCount > 0,
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: format,
                  frameCapacity: 8_192
              ) else { return [] }
        var energy = [Double](repeating: 0, count: pointCount)
        var counts = [Int](repeating: 0, count: pointCount)
        var processedFrames: AVAudioFramePosition = 0

        while processedFrames < totalFrames {
            buffer.frameLength = 0
            try file.read(into: buffer)
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0, let channels = buffer.floatChannelData else { break }

            for frame in 0..<frameCount {
                var frameEnergy = 0.0
                for channel in 0..<Int(format.channelCount) {
                    let value = Double(channels[channel][frame])
                    frameEnergy += value * value
                }
                let position = processedFrames + AVAudioFramePosition(frame)
                let progress = Double(position) / Double(totalFrames)
                let bucket = min(pointCount - 1, Int(progress * Double(pointCount)))
                energy[bucket] += frameEnergy / Double(format.channelCount)
                counts[bucket] += 1
            }
            processedFrames += AVAudioFramePosition(frameCount)
        }

        let values = zip(energy, counts).map { sum, count in
            count > 0 ? Float(sqrt(sum / Double(count))) : 0
        }
        guard let peak = values.max(), peak > 0 else { return values }
        return values.map { min(1, $0 / peak) }
    }

    private nonisolated static func codecName(from description: CMFormatDescription?) -> String {
        guard let description else { return "Unknown" }
        let value = CMFormatDescriptionGetMediaSubType(description)
        let characters = [24, 16, 8, 0].compactMap { shift -> Character? in
            let scalar = UInt8((value >> UInt32(shift)) & 0xff)
            guard scalar >= 32, scalar <= 126 else { return nil }
            return Character(UnicodeScalar(scalar))
        }
        let fourCC = String(characters).trimmingCharacters(in: .whitespaces)
        return fourCC.isEmpty ? String(format: "0x%08X", value) : fourCC.uppercased()
    }

    private nonisolated static func formatDimensions(_ size: CGSize) -> String? {
        guard size.width > 0, size.height > 0 else { return nil }
        return "\(Int(size.width.rounded())) × \(Int(size.height.rounded())) px"
    }

    private nonisolated static func formatBitrate(_ bitrate: Float) -> String? {
        guard bitrate > 0 else { return nil }
        let value = Double(bitrate) / 1_000
        return "\(value.formatted(.number.precision(.fractionLength(0...1)))) kb/s"
    }

    private nonisolated static func logRecoverable(_ error: Error, stage: String) {
        let failure = error as NSError
        logger.warning(
            "Partial metadata failure stage=\(stage, privacy: .public) domain=\(failure.domain, privacy: .public) code=\(failure.code)"
        )
    }
}

private nonisolated struct CommonFileValues: Sendable {
    let filename: String
    let typeName: String
    let fileSize: Int64
    let createdAt: Date?
}
