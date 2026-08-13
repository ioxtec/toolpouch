#if os(watchOS)
import SwiftData
import SwiftUI

@main
struct ToolPouchWatchApp: App {
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let modelContainer = PersistenceContainer.makeModelContainer()
        self.modelContainer = modelContainer
        dependencies = AppDependencies.live(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView(dependencies: dependencies)
                .environmentObject(dependencies.themeStore)
                .toolPouchTheme(dependencies.themeStore)
        }
        .modelContainer(modelContainer)
    }
}
#endif
