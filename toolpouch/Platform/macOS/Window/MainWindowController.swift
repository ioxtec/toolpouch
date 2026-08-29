import AppKit
import SwiftData
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController {
    init(dependencies: AppDependencies) {
        let rootView = ThreeColumnToolNavigationView(dependencies: dependencies)
            .frame(minWidth: 900, minHeight: 560)
            .environmentObject(dependencies.themeStore)
            .toolPouchTheme(dependencies.themeStore)
            .modelContainer(dependencies.modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1160, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ToolPouch"
        window.contentViewController = NSHostingController(rootView: rootView)
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("ToolPouchMainWindow")

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
