import SwiftUI

struct ToolTile: View {
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>?

    init(
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .toolPouchIcon(.medium, weight: .medium)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 22, height: 22)

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let supportedPlatforms {
                Spacer(minLength: 2)
                PlatformAvailabilityBadges(platforms: supportedPlatforms)
            }
        }
        .padding(ToolPouchLayout.Tile.padding)
        .frame(
            maxWidth: .infinity,
            minHeight: supportedPlatforms == nil
                ? ToolPouchLayout.Tile.minimumHeight
                : ToolPouchLayout.Tile.minimumHeightWithPlatforms,
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
