import SwiftUI

struct AppNavigationBar: View {
    @Environment(\.appTheme) private var theme

    let canGoBack: Bool
    let isAtHome: Bool
    let goBack: () -> Void
    let goHome: () -> Void
    let close: (() -> Void)?
    let density: ToolPouchContentDensity

    init(
        canGoBack: Bool,
        isAtHome: Bool,
        goBack: @escaping () -> Void,
        goHome: @escaping () -> Void,
        close: (() -> Void)? = nil,
        density: ToolPouchContentDensity = .regular
    ) {
        self.canGoBack = canGoBack
        self.isAtHome = isAtHome
        self.goBack = goBack
        self.goHome = goHome
        self.close = close
        self.density = density
    }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .toolPouchIcon(.medium, weight: .semibold)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0.35)
            .help("Back")
            .accessibilityLabel("Back")

            Button(action: goHome) {
                Image(systemName: "house")
                    .toolPouchIcon(.medium, weight: .semibold)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .disabled(isAtHome)
            .opacity(isAtHome ? 0.35 : 1)
            .help("All Sections")
            .accessibilityLabel("All Sections")

            Spacer()

            Text("ToolPouch")
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.colors.secondaryText.color)

            if let close {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .toolPouchIcon(.small, weight: .semibold)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Close ToolPouch")
                .accessibilityLabel("Close ToolPouch")
            }
        }
        .padding(.horizontal, density == .compact ? 8 : 12)
        .frame(
            height: density == .compact
                ? 34
                : ToolPouchLayout.Navigation.height
        )
        .toolPouchSurface(
            elevated: true,
            cornerRadius: density == .compact ? 999 : 16
        )
        .padding(.horizontal, density == .compact ? 8 : 10)
        .padding(.vertical, density == .compact ? 5 : 7)
    }
}
