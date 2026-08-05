#if os(macOS)
import AppKit
import UniformTypeIdentifiers

@MainActor
enum MacOSImageFilePicker {
    /// Presents an independent Finder panel instead of attaching a sheet to the compact menu bar window.
    static func chooseImage() -> URL? {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.title = "Choose an Image"
        panel.prompt = "Choose"
        panel.message = "Select an image to inspect locally."
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.level = .modalPanel
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.center()

        return panel.runModal() == .OK ? panel.url : nil
    }

    static func chooseOutputURL(
        sourceURL: URL,
        format: ImageOutputFormat
    ) -> URL? {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSSavePanel()
        panel.title = "Save Converted Image"
        panel.prompt = "Save"
        panel.allowedContentTypes = [format.contentType]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = sourceURL.deletingPathExtension()
            .lastPathComponent + "." + format.fileExtension
        panel.level = .modalPanel
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.center()

        return panel.runModal() == .OK ? panel.url : nil
    }
}
#endif
