import Foundation

nonisolated protocol ImageInspecting: Sendable {
    /// Reads technical image information without modifying the selected file.
    func inspectImage(at url: URL) throws -> ImageInspection
    func readMetadata(at url: URL) throws -> ImageMetadata
    func transform(
        inputURL: URL,
        outputURL: URL,
        options: ImageTransformOptions
    ) throws
}
