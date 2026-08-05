#if os(macOS)
import AppKit
import Testing
@testable import toolpouch

@MainActor
struct SystemClipboardInspectorTests {
    @Test
    func readsTextAndItsRepresentations() throws {
        let pasteboard = makePasteboard()
        pasteboard.setString("ToolPouch clipboard", forType: .string)
        let inspector = SystemClipboardInspector(pasteboard: pasteboard)

        let snapshot = inspector.readSnapshot()
        let item = try #require(snapshot.items.first)

        #expect(item.kind == .text)
        #expect(item.text == "ToolPouch clipboard")
        #expect(item.representations.contains { $0.typeIdentifier == NSPasteboard.PasteboardType.string.rawValue })
    }

    @Test
    func recognizesImageData() throws {
        let pasteboard = makePasteboard()
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        pasteboard.setData(imageData, forType: .png)
        let inspector = SystemClipboardInspector(pasteboard: pasteboard)

        let item = try #require(inspector.readSnapshot().items.first)

        #expect(item.kind == .image)
        #expect(item.imageData == imageData)
    }

    @Test
    func clearsClipboard() {
        let pasteboard = makePasteboard()
        pasteboard.setString("Temporary value", forType: .string)
        let inspector = SystemClipboardInspector(pasteboard: pasteboard)

        inspector.clear()

        #expect(inspector.readSnapshot().isEmpty)
    }

    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("ToolPouchTests.\(UUID().uuidString)")
        )
        pasteboard.clearContents()
        return pasteboard
    }
}
#endif
