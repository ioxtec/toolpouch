import SwiftUI

struct ToolTile: View {
    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>?
    let density: ToolPouchContentDensity
    let isSelected: Bool

    init(
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>? = nil,
        density: ToolPouchContentDensity = .regular,
        isSelected: Bool = false
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
        self.density = density
        self.isSelected = isSelected
    }

    @ViewBuilder
    var body: some View {
        if density == .compact {
            compactTile
        } else {
            regularTile
        }
    }

    private var compactTile: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        theme.colors.primaryAccent.color.opacity(
                            isSelected ? 0.34 : (isHovering ? 0.28 : 0.16)
                        )
                    )

                Image(systemName: systemImage)
                    .toolPouchIcon(.medium, weight: .semibold)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(theme.colors.primaryAccent.color)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.colors.primaryText.color)
                    .lineLimit(1)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)
        }
        .padding(.leading, 7)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(.capsule)
        .toolPouchSurface(interactive: true, cornerRadius: 999)
        .overlay {
            Capsule()
                .fill(
                    theme.colors.primaryAccent.color.opacity(
                        isSelected ? 0.12 : 0
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            Capsule()
                .stroke(
                    theme.colors.primaryAccent.color.opacity(
                        isSelected ? 0.92 : (isHovering ? 0.72 : 0)
                    ),
                    lineWidth: isSelected ? 1.5 : 1
                )
                .allowsHitTesting(false)
        }
        #if os(macOS) || os(iOS)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }

    private var regularTile: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .toolPouchIcon(.medium, weight: .medium)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(theme.colors.primaryAccent.color)

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText.color)
                .lineLimit(2)

            if let supportedPlatforms {
                Spacer(minLength: 2)
                PlatformAvailabilityBadges(platforms: supportedPlatforms)
            }
        }
        .padding(ToolPouchLayout.Tile.padding)
        .frame(
            maxWidth: .infinity,
            minHeight: regularMinimumHeight,
            alignment: .topLeading
        )
        .contentShape(.rect)
        .toolPouchSurface(interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }

    private var regularMinimumHeight: CGFloat {
        return supportedPlatforms == nil
            ? ToolPouchLayout.Tile.minimumHeight
            : ToolPouchLayout.Tile.minimumHeightWithPlatforms
    }
}
