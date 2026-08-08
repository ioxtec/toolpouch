import Foundation

/// Compresses and decompresses folders and single files. Implementations
/// isolate heavy work on their own executor so nothing blocks the main actor.
nonisolated protocol ArchiveManaging: Sendable {
    /// Compresses a folder or a single file into the selected format.
    func compress(
        sourceURL: URL,
        destinationURL: URL,
        format: ArchiveFormat
    ) async throws

    /// Decompresses an archive into a folder beside the archive.
    func decompress(archiveURL: URL) async throws -> URL
}
