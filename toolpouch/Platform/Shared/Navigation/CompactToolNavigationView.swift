import SwiftUI

struct CompactToolNavigationView: View {
    let dependencies: AppDependencies
    let showsPersistentNavigationBar: Bool
    let close: (() -> Void)?
    private let preferredDensity: ToolPouchContentDensity?

    @State private var path: [AppRoute] = []
    @State private var searchQuery = ""

    private var density: ToolPouchContentDensity {
        preferredDensity
            ?? (showsPersistentNavigationBar ? .compact : .regular)
    }

    private var categories: [ToolCategory] {
        dependencies.toolRegistry.categories(for: .current)
    }

    private var availableTools: [ToolDefinition] {
        dependencies.toolRegistry.tools(for: .current)
    }

    init(
        dependencies: AppDependencies,
        showsPersistentNavigationBar: Bool = false,
        close: (() -> Void)? = nil,
        preferredDensity: ToolPouchContentDensity? = nil
    ) {
        self.dependencies = dependencies
        self.showsPersistentNavigationBar = showsPersistentNavigationBar
        self.close = close
        self.preferredDensity = preferredDensity
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsPersistentNavigationBar {
                AppNavigationBar(
                    canGoBack: !path.isEmpty,
                    isAtHome: path.isEmpty,
                    goBack: goBack,
                    goHome: goHome,
                    close: close,
                    density: density
                )

                ToolSearchField(query: $searchQuery)
            }

            NavigationStack(path: $path) {
                Group {
                    if showsPersistentNavigationBar && !searchQuery.isEmpty {
                        ToolSearchResultsView(
                            query: searchQuery,
                            tools: availableTools,
                            categories: categories,
                            selectTool: select
                        )
                    } else {
                        DashboardView(
                            categories: categories,
                            availableTools: availableTools,
                            quickAccessPreferences: dependencies.quickAccessPreferences,
                            density: density,
                            selectTool: select
                        )
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
                .toolbar {
                    if !showsPersistentNavigationBar, !path.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: goHome) {
                                Image(systemName: "house")
                                    .toolPouchIcon(.medium)
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
                    ),
                    density: density
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
        searchQuery = ""
    }

    private func select(_ tool: ToolDefinition) {
        searchQuery = ""
        path.append(.tool(tool.id))
    }
}
