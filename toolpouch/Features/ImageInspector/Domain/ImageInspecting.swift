import Foundation

/// Reads and transforms images. Implementations isolate heavy work on their
/// own actor, so every method is `async` and safe to call from the main actor.
nonisolated protocol ImageInspecting: Sendable {
    /// Reads technical image information without modifying the selected file.
    func inspectImage(at url: URL) async throws -> ImageInspection
    func readMetadata(at url: URL) async throws -> ImageMetadata
    func transform(
        inputURL: URL,
        outputURL: URL,
        options: ImageTransformOptions
    ) async throws
}
