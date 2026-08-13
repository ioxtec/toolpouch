import SwiftUI

struct MenuBarFooter: View {
    let openMainWindow: () -> Void

    var body: some View {
        Button(action: openMainWindow) {
            HStack(spacing: 7) {
                Image(systemName: "macwindow")
                    .toolPouchIcon(.small, weight: .medium)

                Text("Open in Window")
                    .font(.caption.weight(.semibold))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .toolPouchIcon(.small, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
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
