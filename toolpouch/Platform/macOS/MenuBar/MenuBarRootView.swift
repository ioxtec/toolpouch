import SwiftUI

struct MenuBarRootView: View {
    let dependencies: AppDependencies

    var body: some View {
        CompactToolNavigationView(
            dependencies: dependencies,
            showsPersistentNavigationBar: true
        )
        .frame(
            width: ToolPouchLayout.MenuBar.width,
            height: ToolPouchLayout.MenuBar.height
        )
    }
}
