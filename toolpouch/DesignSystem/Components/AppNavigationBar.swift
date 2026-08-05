import SwiftUI

struct AppNavigationBar: View {
    let canGoBack: Bool
    let isAtHome: Bool
    let goBack: () -> Void
    let goHome: () -> Void
    let close: (() -> Void)?

    init(
        canGoBack: Bool,
        isAtHome: Bool,
        goBack: @escaping () -> Void,
        goHome: @escaping () -> Void,
        close: (() -> Void)? = nil
    ) {
        self.canGoBack = canGoBack
        self.isAtHome = isAtHome
        self.goBack = goBack
        self.goHome = goHome
        self.close = close
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
                .foregroundStyle(.secondary)

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
        .padding(.horizontal, 12)
        .frame(height: ToolPouchLayout.Navigation.height)
    }
}
