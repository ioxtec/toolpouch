#if os(macOS)
import AppKit
import UniformTypeIdentifiers

@MainActor
enum MacOSImageFilePicker {
    /// Presents an independent Finder panel instead of attaching a sheet to the compact menu bar window.
    static func chooseImage() -> URL? {
        CenteredFilePanel.chooseFile(
            title: "Choose an Image",
            message: "Select an image to inspect locally.",
            allowedContentTypes: [.image]
        )
    }

    static func chooseOutputURL(
        sourceURL: URL,
        format: ImageOutputFormat
    ) -> URL? {
        CenteredFilePanel.chooseSaveURL(
            title: "Save Converted Image",
            allowedContentTypes: [format.contentType],
            suggestedFilename: sourceURL.deletingPathExtension()
                .lastPathComponent + "." + format.fileExtension
        )
    }
}
#endif
