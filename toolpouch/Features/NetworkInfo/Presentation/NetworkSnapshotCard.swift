import SwiftUI

struct NetworkSnapshotCard: View {
    let snapshot: NetworkInfoSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 12)

            ForEach(Array(snapshot.presentationFields.enumerated()), id: \.element.id) { index, field in
                if index > 0 {
                    Divider()
                        .padding(.leading, 28)
                }

                NetworkInfoRow(field: field)
                    .padding(.vertical, 9)
            }
        }
        .padding(ToolPouchLayout.Tile.padding)
        .glassEffect(
            .regular,
            in: .rect(
                corners: .concentric(
                    minimum: .fixed(ToolPouchLayout.Tile.cornerRadius)
                ),
                isUniform: true
            )
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.deviceName)
                    .font(.headline)
                    .lineLimit(1)

                Text(snapshot.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: snapshot.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(snapshot.isConnected ? .green : .secondary)
                .accessibilityLabel(snapshot.isConnected ? "Connected" : "Disconnected")
        }
    }
}
