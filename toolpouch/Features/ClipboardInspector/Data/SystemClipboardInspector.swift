#if os(macOS)
import AppKit

@MainActor
struct SystemClipboardInspector: ClipboardInspecting {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func readSnapshot() -> ClipboardSnapshot {
        let items = (pasteboard.pasteboardItems ?? []).enumerated().map {
            makeSnapshot(id: $0.offset, item: $0.element)
        }

        return ClipboardSnapshot(
            changeCount: pasteboard.changeCount,
            capturedAt: .now,
            items: items
        )
    }

    func clear() {
        pasteboard.clearContents()
    }

    private func makeSnapshot(
        id: Int,
        item: NSPasteboardItem
    ) -> ClipboardItemSnapshot {
        let representations = item.types.map { type in
            ClipboardRepresentation(
                typeIdentifier: type.rawValue,
                byteCount: item.data(forType: type)?.count ?? 0
            )
        }

        if let fileURL = fileURL(from: item) {
            return ClipboardItemSnapshot(
                id: id,
                kind: .file,
                text: nil,
                imageData: nil,
                fileURL: fileURL,
                representations: representations
            )
        }

        if let imageData = item.data(forType: .png)
            ?? item.data(forType: .tiff)
        {
            return ClipboardItemSnapshot(
                id: id,
                kind: .image,
                text: nil,
                imageData: imageData,
                fileURL: nil,
                representations: representations
            )
        }

        if let text = item.string(forType: .string) {
            return ClipboardItemSnapshot(
                id: id,
                kind: .text,
                text: text,
                imageData: nil,
                fileURL: nil,
                representations: representations
            )
        }

        return ClipboardItemSnapshot(
            id: id,
            kind: .other,
            text: nil,
            imageData: nil,
            fileURL: nil,
            representations: representations
        )
    }

    private func fileURL(from item: NSPasteboardItem) -> URL? {
        guard let value = item.string(forType: .fileURL) else {
            return nil
        }
        return URL(string: value)
    }
}
#endif
