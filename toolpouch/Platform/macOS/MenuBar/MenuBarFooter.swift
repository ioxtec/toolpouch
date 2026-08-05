import SwiftUI

struct MenuBarFooter: View {
    let openMainWindow: () -> Void

    var body: some View {
        Button(action: openMainWindow) {
            HStack(spacing: 9) {
                Image(systemName: "macwindow")
                    .toolPouchIcon(.medium, weight: .medium)

                Text("Open in Window")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .toolPouchIcon(.small, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .frame(
                maxWidth: .infinity,
                minHeight: ToolPouchLayout.MenuBar.footerHeight
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Open ToolPouch in a Window")
        .accessibilityLabel("Open ToolPouch in a Window")
        .background(.ultraThinMaterial)
    }
}
