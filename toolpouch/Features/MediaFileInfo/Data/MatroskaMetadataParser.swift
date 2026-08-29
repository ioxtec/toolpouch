import Foundation

nonisolated struct MatroskaMetadata: Sendable {
    let duration: TimeInterval?
    let dimensions: String?
    let tracks: [MediaTrackInspection]
}

nonisolated struct MatroskaMetadataParser: Sendable {
    func parse(url: URL) throws -> MatroskaMetadata {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        var root = EBMLReader(data: data)

        while let element = try root.nextElement() {
            guard element.id == ElementID.segment else { continue }
            return try parseSegment(data: data, range: element.payloadRange)
        }

        throw MatroskaParserError.missingSegment
    }

    private func parseSegment(data: Data, range: Range<Int>) throws -> MatroskaMetadata {
        var reader = EBMLReader(data: data, range: range)
        var timecodeScale = 1_000_000.0
        var durationUnits: Double?
        var tracks: [MediaTrackInspection] = []

        while let element = try reader.nextElement() {
            switch element.id {
            case ElementID.info:
                let info = try parseInfo(data: data, range: element.payloadRange)
                timecodeScale = info.timecodeScale ?? timecodeScale
                durationUnits = info.duration
            case ElementID.tracks:
                tracks = try parseTracks(data: data, range: element.payloadRange)
            default:
                continue
            }

            if durationUnits != nil, !tracks.isEmpty { break }
        }

        guard !tracks.isEmpty else { throw MatroskaParserError.missingTracks }
        let duration = durationUnits.map { $0 * timecodeScale / 1_000_000_000 }
        let dimensions = tracks.first(where: { $0.kind == .video })?.dimensions
        return MatroskaMetadata(duration: duration, dimensions: dimensions, tracks: tracks)
    }

    private func parseInfo(
        data: Data,
        range: Range<Int>
    ) throws -> (timecodeScale: Double?, duration: Double?) {
        var reader = EBMLReader(data: data, range: range)
        var timecodeScale: Double?
        var duration: Double?

        while let element = try reader.nextElement() {
            switch element.id {
            case ElementID.timecodeScale:
                timecodeScale = Double(reader.unsigned(in: element.payloadRange))
            case ElementID.duration:
                duration = reader.floatingPoint(in: element.payloadRange)
            default:
                continue
            }
        }
        return (timecodeScale, duration)
    }

    private func parseTracks(data: Data, range: Range<Int>) throws -> [MediaTrackInspection] {
        var reader = EBMLReader(data: data, range: range)
        var result: [MediaTrackInspection] = []

        while let element = try reader.nextElement() {
            guard element.id == ElementID.trackEntry else { continue }
            if let track = try parseTrackEntry(
                data: data,
                range: element.payloadRange,
                index: result.count
            ) {
                result.append(track)
            }
        }
        return result
    }

    private func parseTrackEntry(
        data: Data,
        range: Range<Int>,
        index: Int
    ) throws -> MediaTrackInspection? {
        var reader = EBMLReader(data: data, range: range)
        var trackType: UInt64?
        var codecID = "Unknown"
        var language: String?
        var defaultDuration: UInt64?
        var width: UInt64?
        var height: UInt64?
        var sampleRate: Double?
        var channels: UInt64?

        while let element = try reader.nextElement() {
            switch element.id {
            case ElementID.trackType:
                trackType = reader.unsigned(in: element.payloadRange)
            case ElementID.codecID:
                codecID = reader.string(in: element.payloadRange)
            case ElementID.language, ElementID.languageIETF:
                language = reader.string(in: element.payloadRange)
            case ElementID.defaultDuration:
                defaultDuration = reader.unsigned(in: element.payloadRange)
            case ElementID.video:
                let values = try parseVideo(data: data, range: element.payloadRange)
                width = values.width
                height = values.height
            case ElementID.audio:
                let values = try parseAudio(data: data, range: element.payloadRange)
                sampleRate = values.sampleRate
                channels = values.channels
            default:
                continue
            }
        }

        let kind: MediaFileKind
        switch trackType {
        case 1: kind = .video
        case 2: kind = .audio
        default: return nil
        }

        let dimensions = width.flatMap { width in
            height.map { "\(width) × \($0) px" }
        }
        let frameRate = defaultDuration.flatMap { nanoseconds -> String? in
            guard nanoseconds > 0 else { return nil }
            let fps = 1_000_000_000 / Double(nanoseconds)
            return "\(fps.formatted(.number.precision(.fractionLength(0...3)))) fps"
        }
        let formattedSampleRate = sampleRate.map {
            "\(Int($0.rounded()).formatted()) Hz"
        }
        let channelCount = channels.map {
            $0 == 1 ? "Mono" : $0 == 2 ? "Stereo" : "\($0) channels"
        }

        return MediaTrackInspection(
            id: "matroska-\(kind.rawValue)-\(index)",
            kind: kind,
            codec: Self.codecName(for: codecID),
            dimensions: dimensions,
            frameRate: frameRate,
            bitrate: nil,
            sampleRate: formattedSampleRate,
            channelCount: channelCount,
            language: language
        )
    }

    private func parseVideo(
        data: Data,
        range: Range<Int>
    ) throws -> (width: UInt64?, height: UInt64?) {
        var reader = EBMLReader(data: data, range: range)
        var pixelWidth: UInt64?
        var pixelHeight: UInt64?
        var displayWidth: UInt64?
        var displayHeight: UInt64?

        while let element = try reader.nextElement() {
            switch element.id {
            case ElementID.pixelWidth: pixelWidth = reader.unsigned(in: element.payloadRange)
            case ElementID.pixelHeight: pixelHeight = reader.unsigned(in: element.payloadRange)
            case ElementID.displayWidth: displayWidth = reader.unsigned(in: element.payloadRange)
            case ElementID.displayHeight: displayHeight = reader.unsigned(in: element.payloadRange)
            default: continue
            }
        }
        return (displayWidth ?? pixelWidth, displayHeight ?? pixelHeight)
    }

    private func parseAudio(
        data: Data,
        range: Range<Int>
    ) throws -> (sampleRate: Double?, channels: UInt64?) {
        var reader = EBMLReader(data: data, range: range)
        var samplingFrequency: Double?
        var outputSamplingFrequency: Double?
        var channels: UInt64?

        while let element = try reader.nextElement() {
            switch element.id {
            case ElementID.samplingFrequency:
                samplingFrequency = reader.floatingPoint(in: element.payloadRange)
            case ElementID.outputSamplingFrequency:
                outputSamplingFrequency = reader.floatingPoint(in: element.payloadRange)
            case ElementID.channels:
                channels = reader.unsigned(in: element.payloadRange)
            default:
                continue
            }
        }
        return (outputSamplingFrequency ?? samplingFrequency, channels)
    }

    private static func codecName(for id: String) -> String {
        let names = [
            "V_MPEG4/ISO/AVC": "H.264 / AVC",
            "V_MPEGH/ISO/HEVC": "H.265 / HEVC",
            "V_AV1": "AV1",
            "V_VP9": "VP9",
            "V_VP8": "VP8",
            "V_MPEG4/ISO/ASP": "MPEG-4 ASP",
            "V_MPEG2": "MPEG-2 Video",
            "A_AAC": "AAC",
            "A_AC3": "Dolby Digital / AC-3",
            "A_EAC3": "Dolby Digital Plus / E-AC-3",
            "A_DTS": "DTS",
            "A_FLAC": "FLAC",
            "A_MPEG/L3": "MP3",
            "A_OPUS": "Opus",
            "A_VORBIS": "Vorbis",
            "A_PCM/INT/LIT": "PCM",
        ]
        return names[id] ?? id
    }
}

private nonisolated enum MatroskaParserError: LocalizedError {
    case malformedElement
    case missingSegment
    case missingTracks

    var errorDescription: String? {
        switch self {
        case .malformedElement: "The Matroska container contains malformed metadata."
        case .missingSegment: "The file does not contain a Matroska segment."
        case .missingTracks: "No audio or video tracks were found in the Matroska container."
        }
    }
}

private nonisolated struct EBMLElement {
    let id: UInt64
    let payloadRange: Range<Int>
}

private nonisolated struct EBMLReader {
    let data: Data
    private(set) var offset: Int
    private let end: Int

    init(data: Data, range: Range<Int>? = nil) {
        self.data = data
        let bounds = range ?? data.startIndex..<data.endIndex
        offset = bounds.lowerBound
        end = bounds.upperBound
    }

    mutating func nextElement() throws -> EBMLElement? {
        guard offset < end else { return nil }
        let id = try readVariableInteger(removingMarker: false)
        let size = try readVariableInteger(removingMarker: true)
        let payloadStart = offset
        let payloadEnd: Int

        if size.isUnknownSize {
            payloadEnd = end
        } else {
            guard size.value <= UInt64(end - payloadStart) else {
                throw MatroskaParserError.malformedElement
            }
            payloadEnd = payloadStart + Int(size.value)
        }
        offset = payloadEnd
        return EBMLElement(id: id.value, payloadRange: payloadStart..<payloadEnd)
    }

    func unsigned(in range: Range<Int>) -> UInt64 {
        data[range].reduce(0) { ($0 << 8) | UInt64($1) }
    }

    func floatingPoint(in range: Range<Int>) -> Double? {
        switch range.count {
        case 4:
            return Double(Float(bitPattern: UInt32(unsigned(in: range))))
        case 8:
            return Double(bitPattern: unsigned(in: range))
        default:
            return nil
        }
    }

    func string(in range: Range<Int>) -> String {
        String(decoding: data[range], as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))
    }

    private mutating func readVariableInteger(
        removingMarker: Bool
    ) throws -> (value: UInt64, isUnknownSize: Bool) {
        guard offset < end else { throw MatroskaParserError.malformedElement }
        let first = data[offset]
        guard first != 0 else { throw MatroskaParserError.malformedElement }
        let leadingZeros = first.leadingZeroBitCount
        let length = leadingZeros + 1
        guard length <= 8, offset + length <= end else {
            throw MatroskaParserError.malformedElement
        }

        var value = UInt64(removingMarker ? first & (0xff >> length) : first)
        for index in 1..<length {
            value = (value << 8) | UInt64(data[offset + index])
        }
        offset += length

        let unknownValue = (UInt64(1) << UInt64(length * 7)) - 1
        return (value, removingMarker && value == unknownValue)
    }
}

private nonisolated enum ElementID {
    static let segment: UInt64 = 0x18538067
    static let info: UInt64 = 0x1549A966
    static let timecodeScale: UInt64 = 0x2AD7B1
    static let duration: UInt64 = 0x4489
    static let tracks: UInt64 = 0x1654AE6B
    static let trackEntry: UInt64 = 0xAE
    static let trackType: UInt64 = 0x83
    static let codecID: UInt64 = 0x86
    static let language: UInt64 = 0x22B59C
    static let languageIETF: UInt64 = 0x22B59D
    static let defaultDuration: UInt64 = 0x23E383
    static let video: UInt64 = 0xE0
    static let pixelWidth: UInt64 = 0xB0
    static let pixelHeight: UInt64 = 0xBA
    static let displayWidth: UInt64 = 0x54B0
    static let displayHeight: UInt64 = 0x54BA
    static let audio: UInt64 = 0xE1
    static let samplingFrequency: UInt64 = 0xB5
    static let outputSamplingFrequency: UInt64 = 0x78B5
    static let channels: UInt64 = 0x9F
}
