import Foundation
import UniformTypeIdentifiers

nonisolated enum ArchiveFormat: String, CaseIterable, Identifiable, Sendable {
    case zip
    case gzip
    case bzip2
    case xz
    case tar
    case sevenZip
    case rar
    case iso

    var id: Self { self }

    static let supportedCompressionFormats: [ArchiveFormat] = [
        .zip,
        .gzip,
        .bzip2,
        .xz,
        .tar,
    ]

    var title: String {
        switch self {
        case .zip: "ZIP"
        case .gzip: "GZIP"
        case .bzip2: "BZIP2"
        case .xz: "XZ"
        case .tar: "TAR"
        case .sevenZip: "7Z"
        case .rar: "RAR"
        case .iso: "ISO"
        }
    }

    var description: String {
        switch self {
        case .zip: "Standard archive that can bundle whole folders."
        case .gzip: "Single-file compression used for logs and data."
        case .bzip2: "Single-file compression with strong ratios."
        case .xz: "Modern single-file compression used for distribution."
        case .tar: "Bundle folders into a tape archive."
        case .sevenZip: "Archive that can bundle whole folders."
        case .rar: "Read-only: extracts RAR and RAR5 archives."
        case .iso: "Optical disc image that can bundle whole folders."
        }
    }

    var fileExtension: String {
        switch self {
        case .zip: "zip"
        case .gzip: "gz"
        case .bzip2: "bz2"
        case .xz: "xz"
        case .tar: "tar"
        case .sevenZip: "7z"
        case .rar: "rar"
        case .iso: "iso"
        }
    }

    var contentType: UTType {
        switch self {
        case .zip: .zip
        case .gzip: .gzip
        case .bzip2: UTType(filenameExtension: "bz2") ?? .data
        case .xz: UTType(filenameExtension: "xz") ?? .data
        case .tar: UTType(filenameExtension: "tar") ?? .data
        case .sevenZip: UTType(filenameExtension: "7z") ?? .data
        case .rar: UTType(filenameExtension: "rar") ?? .data
        case .iso: UTType(filenameExtension: "iso") ?? .data
        }
    }

    /// Compression-only formats archive a single file, so only a folder
    /// with one entry is compressible.
    var canArchiveFolders: Bool {
        switch self {
        case .zip, .tar, .sevenZip, .iso: true
        case .gzip, .bzip2, .xz, .rar: false
        }
    }

    /// Formats that can only be decompressed.
    var isReadOnly: Bool {
        self == .rar
    }
}
