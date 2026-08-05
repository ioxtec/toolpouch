import SwiftUI

struct WiFiScannerView: View {
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
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .task { await model.scan() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Wi-Fi Scanner")
                    .font(.title2.bold())
                Text("Nearby networks ordered by signal strength.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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
            .disabled(model.isScanning)
        }
        .padding(ToolPouchLayout.Content.padding)
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = model.errorMessage {
            ContentUnavailableView(
                "Unable to Scan Wi-Fi",
                systemImage: "wifi.exclamationmark",
                description: Text(errorMessage)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.networks.isEmpty, model.isScanning {
            ProgressView("Scanning nearby networks…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.networks.isEmpty {
            ContentUnavailableView(
                "No Networks Found",
                systemImage: "wifi.slash",
                description: Text("Try scanning again closer to a Wi-Fi access point.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(model.networks) { network in
                WiFiNetworkRow(network: network)
            }
            #if !os(watchOS)
            .listStyle(.inset)
            #endif
        }
    }
}

private struct WiFiNetworkRow: View {
    let network: WiFiNetwork

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: network.signalSystemImage)
                .toolPouchIcon(.medium)
                .foregroundStyle(signalColor)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(network.name)
                        .font(.headline)
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
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(network.rssi) dBm")
                .font(.body.monospaced().weight(.medium))
                .foregroundStyle(signalColor)
        }
        .padding(.vertical, 5)
    }

    private var signalColor: Color {
        switch network.signalQuality {
        case 0.7...: .green
        case 0.4...: .yellow
        default: .red
        }
    }
}
