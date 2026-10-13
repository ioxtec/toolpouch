import Foundation

/// Stores a compact append-only history locally. Appending one line avoids
/// rewriting the complete history at every sample, which keeps disk activity
/// small even when the user selects a 24-hour retention period.
@MainActor
final class SystemStatsHistoryStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
    }

    func load() -> [SystemStatsSample] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return data.split(separator: 0x0A)
            .compactMap { try? decoder.decode(SystemStatsSample.self, from: Data($0)) }
            .sorted { $0.capturedAt < $1.capturedAt }
    }

    func append(_ sample: SystemStatsSample) {
        guard var data = try? encoder.encode(sample) else { return }
        data.append(0x0A)
        prepareDirectory()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? data.write(to: fileURL, options: .atomic)
            return
        }
        guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }
    }

    func replace(with samples: [SystemStatsSample]) {
        var data = Data()
        for sample in samples {
            guard let encoded = try? encoder.encode(sample) else { continue }
            data.append(encoded)
            data.append(0x0A)
        }
        prepareDirectory()
        try? data.write(to: fileURL, options: .atomic)
    }

    private func prepareDirectory() {
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private static var defaultFileURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("ToolPouch", isDirectory: true)
            .appendingPathComponent("system-stats-history.jsonl")
    }
}
