import Foundation
import Observation

@MainActor
@Observable
final class ArchiveToolModel {
    enum Mode: String, CaseIterable, Identifiable, Sendable {
        case compress
        case decompress

        var id: Self { self }

        var title: String {
            switch self {
            case .compress: "Compress"
            case .decompress: "Decompress"
            }
        }
    }

    enum State: Equatable {
        case idle
        case working
        case succeeded(String)
        case failed(String)
    }

    private let archiveManager: any ArchiveManaging

    var mode: Mode = .compress
    var selectedFormat: ArchiveFormat = .zip
    private(set) var state: State = .idle

    var isWorking: Bool {
        if case .working = state { return true }
        return false
    }

    init(archiveManager: any ArchiveManaging) {
        self.archiveManager = archiveManager
    }

    func compress(folderURL: URL) {
        guard !isWorking else { return }
        state = .working
        let format = selectedFormat

        Task {
            let result = await compressAsync(folderURL: folderURL, format: format)
            state = result
        }
    }

    func decompress(archiveURL: URL) {
        guard !isWorking else { return }
        state = .working

        Task {
            let result = await decompressAsync(archiveURL: archiveURL)
            state = result
        }
    }

    private func compressAsync(
        folderURL: URL,
        format: ArchiveFormat
    ) async -> State {
        do {
            let destination = destinationURL(for: folderURL, format: format)
            try await archiveManager.compress(
                sourceURL: folderURL,
                destinationURL: destination,
                format: format
            )
            return .succeeded(
                "Compressed to \(destination.lastPathComponent) next to the source."
            )
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func decompressAsync(archiveURL: URL) async -> State {
        do {
            let output = try await archiveManager.decompress(archiveURL: archiveURL)
            return .succeeded(
                "Extracted \(archiveURL.lastPathComponent) into \(output.lastPathComponent)."
            )
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func destinationURL(for sourceURL: URL, format: ArchiveFormat) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let name = sourceURL.deletingPathExtension().lastPathComponent
        return directory.appendingPathComponent("\(name).\(format.fileExtension)")
    }
}
