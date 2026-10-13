import SwiftUI

struct MenuBarFooter: View {
    let openMainWindow: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            footerButton(
                "Open in Window",
                systemImage: "macwindow",
                action: openMainWindow
            )
            footerButton(
                "Settings",
                systemImage: "gearshape",
                action: openSettings
            )
        }
        .padding(.horizontal, ToolPouchLayout.MenuBar.contentPadding)
        .frame(maxWidth: .infinity, minHeight: ToolPouchLayout.MenuBar.footerHeight)
        .background(.ultraThinMaterial)
    }

    private func footerButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title.localizedInterfaceText, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .toolPouchSurface(interactive: true)
        .help(title.localizedInterfaceText)
        .accessibilityLabel(title.localizedInterfaceText)
    }
}
