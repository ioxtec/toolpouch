#if os(iOS)
import SwiftData
import SwiftUI

@main
struct ToolPouchMobileApp: App {
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let modelContainer = PersistenceContainer.makeModelContainer()
        self.modelContainer = modelContainer
        dependencies = AppDependencies.live(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            AdaptiveMobileRootView(dependencies: dependencies)
        }
        .modelContainer(modelContainer)
    }
}
#endif
