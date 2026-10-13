import SwiftUI

struct MenuBarRootView: View {
    let dependencies: AppDependencies
    let openMainWindow: (ToolDefinition.ID?) -> Void
    let openSettings: () -> Void
    let close: () -> Void
    let resizeToFit: (CGFloat) -> CGFloat

    @State private var panelHeight = ToolPouchLayout.MenuBar.height

    var body: some View {
        VStack(spacing: 0) {
            CompactToolNavigationView(
                dependencies: dependencies,
                showsPersistentNavigationBar: true,
                close: close
            )
            .environment(
                \.openToolInWindow,
                OpenToolInWindowAction { openMainWindow($0) }
            )

            Divider()

            MenuBarFooter(
                openMainWindow: { openMainWindow(nil) },
                openSettings: openSettings
            )
        }
        .frame(
            width: ToolPouchLayout.MenuBar.width,
            height: panelHeight
        )
        .environment(\.toolPouchPresentationMode, .compactPanel)
        .onPreferenceChange(ToolContentHeightPreferenceKey.self) { contentHeight in
            guard contentHeight > 0 else { return }
            let requestedHeight = contentHeight + ToolPouchLayout.MenuBar.chromeHeight
            let fittedHeight = resizeToFit(requestedHeight)
            guard abs(fittedHeight - panelHeight) > 1 else { return }
            panelHeight = fittedHeight
        }
    }
}
