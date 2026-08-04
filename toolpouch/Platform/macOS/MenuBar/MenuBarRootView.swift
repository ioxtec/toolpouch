import SwiftUI

struct MenuBarRootView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            DashboardView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .frame(
            width: ToolPouchLayout.MenuBar.width,
            height: ToolPouchLayout.MenuBar.height
        )
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case let .category(category):
            if category.id == .network {
                NetworkInfoView(dependencies: dependencies)
            } else {
                ToolCategoryView(category: category)
            }
        }
    }
}
