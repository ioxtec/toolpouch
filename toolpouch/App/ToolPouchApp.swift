import SwiftData
import SwiftUI

@main
struct ToolPouchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let modelContainer = PersistenceContainer.makeModelContainer()
        self.modelContainer = modelContainer
        dependencies = AppDependencies.live(modelContainer: modelContainer)
        appDelegate.configure(dependencies: dependencies)
    }

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .modelContainer(modelContainer)
    }
}
