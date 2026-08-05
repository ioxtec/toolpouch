import SwiftUI

struct NetworkInfoHeader: View {
    let isRefreshing: Bool
    let refresh: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScreenHeader(
                title: "Network Info",
                subtitle: "Current details and recent device snapshots."
            )

            Button(action: refresh) {
                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .toolPouchIcon(.small)
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .disabled(isRefreshing)
            .help("Refresh Network Info")
            .accessibilityLabel("Refresh Network Info")
        }
    }
}
