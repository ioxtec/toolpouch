import CryptoKit
import Foundation

nonisolated struct CryptoKitHashCalculator: HashCalculating {
    private static let chunkSize = 1_048_576

    func hash(_ data: Data, using algorithm: HashAlgorithm) -> HashDigest {
        let value: String

        switch algorithm {
        case .sha256:
            value = hexadecimal(SHA256.hash(data: data))
        case .sha512:
            value = hexadecimal(SHA512.hash(data: data))
        case .md5:
            value = hexadecimal(Insecure.MD5.hash(data: data))
        }

        return HashDigest(algorithm: algorithm, value: value)
    }

    func hash(
        fileAt url: URL,
        using algorithm: HashAlgorithm
    ) async throws -> HashDigest {
        try await Task.detached(priority: .userInitiated) {
            try self.hashFileSynchronously(at: url, using: algorithm)
        }.value
    }

    private func hashFileSynchronously(
        at url: URL,
        using algorithm: HashAlgorithm
    ) throws -> HashDigest {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: url)
        } catch let error as CocoaError where error.code == .fileReadNoPermission {
            throw HashCalculationError.fileAccessDenied
        } catch {
            throw HashCalculationError.fileReadFailed(error.localizedDescription)
        }
        defer { try? fileHandle.close() }

        do {
            switch algorithm {
            case .sha256:
                var hasher = SHA256()
                try update(&hasher, from: fileHandle)
                return HashDigest(
                    algorithm: algorithm,
                    value: hexadecimal(hasher.finalize())
                )
            case .sha512:
                var hasher = SHA512()
                try update(&hasher, from: fileHandle)
                return HashDigest(
                    algorithm: algorithm,
                    value: hexadecimal(hasher.finalize())
                )
            case .md5:
                var hasher = Insecure.MD5()
                try update(&hasher, from: fileHandle)
                return HashDigest(
                    algorithm: algorithm,
                    value: hexadecimal(hasher.finalize())
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as HashCalculationError {
            throw error
        } catch {
            throw HashCalculationError.fileReadFailed(error.localizedDescription)
        }
    }

    private func update<Hasher: HashFunction>(
        _ hasher: inout Hasher,
        from fileHandle: FileHandle
    ) throws {
        while true {
            try Task.checkCancellation()
            guard let data = try fileHandle.read(upToCount: Self.chunkSize),
                  !data.isEmpty
            else { return }
            hasher.update(data: data)
        }
    }

    private func hexadecimal<Digest: Sequence>(_ digest: Digest) -> String
    where Digest.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
