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

        guard let dependencies else {
            assertionFailure("App dependencies must be configured before launch.")
            return
        }

        statusItemController = StatusItemController(dependencies: dependencies)
    }
}
