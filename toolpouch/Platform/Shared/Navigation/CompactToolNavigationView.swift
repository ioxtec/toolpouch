import SwiftUI

struct CompactToolNavigationView: View {
    let dependencies: AppDependencies
    let showsPersistentNavigationBar: Bool

    @State private var path: [AppRoute] = []

    init(
        dependencies: AppDependencies,
        showsPersistentNavigationBar: Bool = false
    ) {
        self.dependencies = dependencies
        self.showsPersistentNavigationBar = showsPersistentNavigationBar
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsPersistentNavigationBar {
                AppNavigationBar(
                    canGoBack: !path.isEmpty,
                    isAtHome: path.isEmpty,
                    goBack: goBack,
                    goHome: goHome
                )
                Divider()
            }

            NavigationStack(path: $path) {
                DashboardView(
                    categories: dependencies.toolRegistry.categories(for: .current)
                )
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
                .toolbar {
                    if !showsPersistentNavigationBar, !path.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: goHome) {
                                Image(systemName: "house")
                            }
                            .accessibilityLabel("Home")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case let .category(categoryID):
            if let category = dependencies.toolRegistry.category(id: categoryID) {
                ToolCategoryView(
                    category: category,
                    tools: dependencies.toolRegistry.tools(
                        in: categoryID,
                        for: .current
                    )
                )
                .navigationTitle(category.title)
            }
        case let .tool(toolID):
            if let destination = dependencies.toolRegistry.destination(
                for: toolID,
                dependencies: dependencies
            ) {
                destination
                    .navigationTitle(
                        dependencies.toolRegistry.tool(id: toolID)?.title ?? "Tool"
                    )
            }
        }
    }

    private func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func goHome() {
        path.removeAll()
    }
}
