import Foundation

nonisolated protocol HashCalculating: Sendable {
    /// Calculates a digest for data already held in memory.
    func hash(_ data: Data, using algorithm: HashAlgorithm) -> HashDigest
    /// Reads and hashes a file without requiring the caller to load the complete file into memory.
    func hash(fileAt url: URL, using algorithm: HashAlgorithm) async throws -> HashDigest
}
