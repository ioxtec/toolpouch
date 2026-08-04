import SwiftUI

struct AppNavigationBar: View {
    let canGoBack: Bool
    let isAtHome: Bool
    let goBack: () -> Void
    let goHome: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0.35)
            .help("Back")
            .accessibilityLabel("Back")

            Button(action: goHome) {
                Image(systemName: "house")
                    .frame(width: 18, height: 18)
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
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .frame(height: ToolPouchLayout.Navigation.height)
    }
}
