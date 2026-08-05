import SwiftUI

struct MenuBarRootView: View {
    let dependencies: AppDependencies
    let openMainWindow: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CompactToolNavigationView(
                dependencies: dependencies,
                showsPersistentNavigationBar: true,
                close: close
            )

            Divider()

            MenuBarFooter(openMainWindow: openMainWindow)
        }
        .frame(
            width: ToolPouchLayout.MenuBar.width,
            height: ToolPouchLayout.MenuBar.height
        )
    }
}
