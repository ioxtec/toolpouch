import SwiftUI

struct RecentDevicesCard: View {
    let snapshots: [NetworkInfoSnapshot]
    let selectedSnapshotID: UUID?
    let onSelect: (NetworkInfoSnapshot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Devices")
                .font(.headline)

            ForEach(snapshots) { snapshot in
                Button {
                    onSelect(snapshot)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: systemImage(for: snapshot.deviceKind))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.deviceName)
                                .lineLimit(1)
                            Text(snapshot.capturedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if snapshot.id == selectedSnapshotID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ToolPouchLayout.Tile.padding)
        .glassEffect(
            .regular.interactive(),
            in: .rect(
                corners: .concentric(
                    minimum: .fixed(ToolPouchLayout.Tile.cornerRadius)
                ),
                isUniform: true
            )
        )
    }

    private func systemImage(for kind: DeviceKind) -> String {
        switch kind {
        case .desktop, .laptop:
            "desktopcomputer"
        case .phone:
            "iphone"
        case .tablet:
            "ipad"
        case .watch:
            "applewatch"
        case .spatialComputer:
            "visionpro"
        case .television:
            "appletv"
        case .unknown:
            "questionmark.square"
        }
    }
}
