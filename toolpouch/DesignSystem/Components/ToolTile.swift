import SwiftUI

struct ToolTile: View {
    let title: String
    let description: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2.weight(.medium))
                .symbolRenderingMode(.monochrome)
                .frame(width: 28, height: 28, alignment: .leading)

            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(ToolPouchLayout.Tile.padding)
        .frame(
            maxWidth: .infinity,
            minHeight: ToolPouchLayout.Tile.minimumHeight,
            alignment: .topLeading
        )
        .contentShape(.rect)
        .glassEffect(
            .regular.interactive(),
            in: .rect(
                corners: .concentric(
                    minimum: .fixed(ToolPouchLayout.Tile.cornerRadius)
                ),
                isUniform: true
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
}
