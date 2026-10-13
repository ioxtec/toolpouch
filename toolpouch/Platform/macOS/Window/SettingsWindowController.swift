import AppKit
import SwiftData
import SwiftUI

/// Owns the settings window explicitly because the menu-bar application runs
/// with accessory activation policy. In that mode there may be no responder
/// available for the legacy `showSettingsWindow:` action used by regular apps.
@MainActor
final class SettingsWindowController: NSWindowController {
    init(dependencies: AppDependencies) {
        let rootView = SettingsView()
            .environmentObject(dependencies.themeStore)
            .appLanguage(dependencies.languageStore, rebuildOnChange: false)
            .toolPouchTheme(dependencies.themeStore)
            .modelContainer(dependencies.modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ToolPouch Settings".localizedInterfaceText
        window.contentMinSize = NSSize(width: 600, height: 380)
        window.contentViewController = NSHostingController(rootView: rootView)
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("ToolPouchSettingsWindow")

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.title = "ToolPouch Settings".localizedInterfaceText
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}
