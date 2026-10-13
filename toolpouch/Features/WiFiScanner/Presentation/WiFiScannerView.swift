import SwiftUI

struct WiFiScannerView: View {
    @Environment(\.appTheme) private var theme
    @State private var model: WiFiScannerViewModel

    init(
        scanner: any WiFiScanning,
        authorizer: any WiFiScanAuthorizing
    ) {
        _model = State(
            initialValue: WiFiScannerViewModel(
                scanner: scanner,
                authorizer: authorizer
            )
        )
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header
                content
            }
        }
        .scrollIndicators(.never)
        .task { await model.scan() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: ToolPouchLayout.Spacing.large) {
            ScreenHeader(
                title: "Wi-Fi Scanner",
                subtitle: "Nearby networks ordered by signal strength.",
                density: isWatch ? .compact : .regular
            )

            Spacer()

            Button {
                Task { await model.scan() }
            } label: {
                if model.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
            }
            .toolPouchPrimaryAction()
            .disabled(model.isScanning)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = model.errorMessage {
            ContentUnavailableView(
                "Unable to Scan Wi-Fi",
                systemImage: "wifi.exclamationmark",
                description: Text(errorMessage)
            )
            .frame(maxWidth: .infinity, minHeight: 150)
        } else if model.networks.isEmpty, model.isScanning {
            ProgressView("Scanning nearby networks…")
                .frame(maxWidth: .infinity, minHeight: 150)
        } else if model.networks.isEmpty {
            ContentUnavailableView(
                "No Networks Found",
                systemImage: "wifi.slash",
                description: Text("Try scanning again closer to a Wi-Fi access point.")
            )
            .frame(maxWidth: .infinity, minHeight: 150)
        } else {
            ToolSectionCard("Nearby networks") {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.networks.enumerated()), id: \.element.id) { index, network in
                        WiFiNetworkRow(network: network)
                        if index < model.networks.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var isWatch: Bool {
        #if os(watchOS)
        true
        #else
        false
        #endif
    }
}

private struct WiFiNetworkRow: View {
    @Environment(\.appTheme) private var theme
    let network: WiFiNetwork

    var body: some View {
        HStack(spacing: ToolPouchLayout.Spacing.large) {
            Image(systemName: network.signalSystemImage)
                .toolPouchIcon(.medium)
                .foregroundStyle(signalColor)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.xSmall) {
                HStack(spacing: 6) {
                    Text(network.name)
                        .font(ToolPouchLayout.Typography.body.weight(.semibold))
                        .lineLimit(1)
                    if network.isSecure {
                        Image(systemName: "lock.fill")
                            .toolPouchIcon(.small)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    if let channel = network.channel {
                        Text("Channel \(channel)")
                    }
                    if let bssid = network.bssid {
                        Text(bssid)
                    }
                }
                .font(ToolPouchLayout.Typography.supporting.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text("\(network.rssi) dBm")
                .font(ToolPouchLayout.Typography.body.monospaced().weight(.medium))
                .foregroundStyle(signalColor)
        }
        .padding(.vertical, ToolPouchLayout.Spacing.medium)
    }

    private var signalColor: Color {
        switch network.signalQuality {
        case 0.7...: theme.colors.success.color
        case 0.4...: theme.colors.warning.color
        default: theme.colors.danger.color
        }
    }
}
