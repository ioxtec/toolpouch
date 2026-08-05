#if os(macOS)
import Foundation

nonisolated enum ClipboardContentKind: String, Sendable {
    case text
    case image
    case file
    case other

    var title: String {
        switch self {
        case .text: "Text"
        case .image: "Image"
        case .file: "File"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .text: "text.alignleft"
        case .image: "photo"
        case .file: "doc"
        case .other: "shippingbox"
        }
    }
}

nonisolated struct ClipboardRepresentation: Identifiable, Hashable, Sendable {
    let typeIdentifier: String
    let byteCount: Int

    var id: String { typeIdentifier }
}

nonisolated struct ClipboardItemSnapshot: Identifiable, Sendable {
    let id: Int
    let kind: ClipboardContentKind
    let text: String?
    let imageData: Data?
    let fileURL: URL?
    let representations: [ClipboardRepresentation]

    var estimatedByteCount: Int {
        switch kind {
        case .text:
            text?.utf8.count ?? 0
        case .image:
            imageData?.count ?? 0
        case .file:
            fileURL?.path(percentEncoded: false).utf8.count ?? 0
        case .other:
            representations.map(\.byteCount).max() ?? 0
        }
    }
}

nonisolated struct ClipboardSnapshot: Sendable {
    let changeCount: Int
    let capturedAt: Date
    let items: [ClipboardItemSnapshot]

    var isEmpty: Bool { items.isEmpty }

    static func empty(changeCount: Int = 0) -> ClipboardSnapshot {
        ClipboardSnapshot(
            changeCount: changeCount,
            capturedAt: .now,
            items: []
        )
    }
}
#endif
