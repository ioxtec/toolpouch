#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

@MainActor
enum SystemClipboard {
    static func copy(_ value: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = value
        #endif
    }

    #if os(macOS)
    static func copy(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
    #elseif os(iOS)
    static func copy(_ image: UIImage) {
        UIPasteboard.general.image = image
    }
    #endif
}
