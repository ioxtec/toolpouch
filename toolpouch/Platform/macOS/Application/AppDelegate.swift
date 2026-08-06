import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var dependencies: AppDependencies?

    func configure(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyApplicationIcon()

        guard let dependencies else {
            assertionFailure("App dependencies must be configured before launch.")
            return
        }

        statusItemController = StatusItemController(dependencies: dependencies)
    }

    /// Applies the bundled icon explicitly so development builds do not depend on the Dock icon cache.
    private func applyApplicationIcon() {
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return
        }
        NSApp.applicationIconImage = icon
    }
}
