#if os(macOS)
import AppKit
import UniformTypeIdentifiers

@MainActor
enum CenteredFilePanel {
    static func chooseFile(
        title: String,
        message: String? = nil,
        allowedContentTypes: [UTType] = [.item]
    ) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        if let message {
            panel.message = message
        }
        panel.prompt = "Choose"
        panel.allowedContentTypes = allowedContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        prepare(panel)
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func chooseDirectory(
        title: String,
        message: String? = nil,
        prompt: String = "Choose Folder",
        initialDirectory: URL? = nil,
        showsHiddenFiles: Bool = false
    ) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        if let message {
            panel.message = message
        }
        panel.prompt = prompt
        panel.directoryURL = initialDirectory
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.showsHiddenFiles = showsHiddenFiles
        prepare(panel)
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func chooseSaveURL(
        title: String,
        prompt: String = "Save",
        allowedContentTypes: [UTType],
        suggestedFilename: String
    ) -> URL? {
        let panel = NSSavePanel()
        panel.title = title
        panel.prompt = prompt
        panel.allowedContentTypes = allowedContentTypes
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = suggestedFilename
        prepare(panel)
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func prepare(_ panel: NSSavePanel) {
        NSApp.activate(ignoringOtherApps: true)
        panel.level = .modalPanel
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.contentView?.layoutSubtreeIfNeeded()

        let screen = activeScreen
        let frame = panel.frame
        panel.setFrameOrigin(
            NSPoint(
                x: screen.visibleFrame.midX - frame.width / 2,
                y: screen.visibleFrame.midY - frame.height / 2
            )
        )
    }

    private static var activeScreen: NSScreen {
        if let screen = NSApp.keyWindow?.screen ?? NSApp.mainWindow?.screen {
            return screen
        }

        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}
#endif
