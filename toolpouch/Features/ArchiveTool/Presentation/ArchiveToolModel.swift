import Foundation
import Observation
#if os(macOS)
import AppKit
#endif

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
        let format = selectedFormat
        #if os(macOS)
        guard let destination = ArchiveFilePanels.saveArchive(source: folderURL, format: format) else { return }
        #else
        let destination = destinationURL(for: folderURL, format: format)
        #endif
        state = .working

        Task {
            let sourceAccess = folderURL.startAccessingSecurityScopedResource()
            let destinationAccess = destination.startAccessingSecurityScopedResource()
            defer {
                if sourceAccess { folderURL.stopAccessingSecurityScopedResource() }
                if destinationAccess { destination.stopAccessingSecurityScopedResource() }
            }
            let result = await compressAsync(folderURL: folderURL, destination: destination, format: format)
            state = result
        }
    }

    func decompress(archiveURL: URL) {
        guard !isWorking else { return }
        #if os(macOS)
        guard let directory = ArchiveFilePanels.extractionDirectory() else { return }
        // The user grants access to the parent directory. Never extract into
        // an existing tree or silently merge it with their files.
        let destination = directory.appendingPathComponent(
            archiveURL.deletingPathExtension().lastPathComponent + "-" + UUID().uuidString.prefix(8)
        )
        #else
        let directory = archiveURL.deletingLastPathComponent()
        let destination = archiveURL.deletingPathExtension()
        #endif
        state = .working

        Task {
            let sourceAccess = archiveURL.startAccessingSecurityScopedResource()
            let destinationAccess = directory.startAccessingSecurityScopedResource()
            defer {
                if sourceAccess { archiveURL.stopAccessingSecurityScopedResource() }
                if destinationAccess { directory.stopAccessingSecurityScopedResource() }
            }
            let result = await decompressAsync(archiveURL: archiveURL, destination: destination)
            state = result
        }
    }

    private func compressAsync(
        folderURL: URL,
        destination: URL,
        format: ArchiveFormat
    ) async -> State {
        do {
            try await archiveManager.compress(
                sourceURL: folderURL,
                destinationURL: destination,
                format: format
            )
            return .succeeded(
                String(format: "Saved archive: %@".localizedInterfaceText, destination.lastPathComponent)
            )
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func decompressAsync(archiveURL: URL, destination: URL) async -> State {
        do {
            let output = try await archiveManager.decompress(archiveURL: archiveURL, destinationURL: destination)
            return .succeeded(
                String(format: "Extracted to: %@".localizedInterfaceText, output.lastPathComponent)
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

    #if os(macOS)
    func chooseSource(compress: Bool) {
        guard !isWorking, let source = ArchiveFilePanels.source(compress: compress) else { return }
        if compress { self.compress(folderURL: source) }
        else { decompress(archiveURL: source) }
    }
    #endif
}

#if os(macOS)
@MainActor
private enum ArchiveFilePanels {
    static func source(compress: Bool) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = compress
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func saveArchive(source: URL, format: ArchiveFormat) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = source.lastPathComponent + "." + format.fileExtension
        panel.allowedContentTypes = [format.contentType]
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func extractionDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to extract the archive.".localizedInterfaceText
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }
}
#endif
