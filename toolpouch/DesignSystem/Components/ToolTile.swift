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
    let badgeValue: Int?

    init(
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>? = nil,
        density: ToolPouchContentDensity = .regular,
        isSelected: Bool = false,
        badgeValue: Int? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
        self.density = density
        self.isSelected = isSelected
        self.badgeValue = badgeValue
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
        HStack(alignment: .top, spacing: 7) {
            ZStack {
                Circle()
                    .fill(theme.colors.accentButtonBackground.color)
                    .overlay {
                        Circle().fill(
                            theme.colors.primaryAccent.color.opacity(
                                isSelected ? 0.16 : (isHovering ? 0.10 : 0)
                            )
                        )
                    }

                Image(systemName: systemImage)
                    .toolPouchIcon(.small, weight: .semibold)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(theme.colors.primaryAccent.color)
            }
            .frame(
                width: ToolPouchLayout.Tile.compactIconDiameter,
                height: ToolPouchLayout.Tile.compactIconDiameter
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title.localizedInterfaceText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.colors.primaryText.color)
                        .lineLimit(1)

                    if let badgeValue {
                        compactCountBadge(badgeValue)
                    }

                    Spacer(minLength: 0)
                }

                Text(description.localizedInterfaceText)
                    .font(.caption2)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .lineLimit(1)
            }
        }
        .padding(ToolPouchLayout.Tile.compactPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: ToolPouchLayout.Tile.compactMinimumHeight,
            alignment: .topLeading
        )
        .contentShape(.rect)
        .toolPouchSurface(
            interactive: true,
            cornerRadius: ToolPouchLayout.Tile.cornerRadius
        )
        .overlay {
            RoundedRectangle(cornerRadius: ToolPouchLayout.Tile.cornerRadius)
                .fill(
                    theme.colors.primaryAccent.color.opacity(
                        isSelected ? 0.12 : 0
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ToolPouchLayout.Tile.cornerRadius)
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
        .accessibilityLabel(title.localizedInterfaceText)
        .accessibilityHint(accessibilityHint)
        #if os(macOS)
        .help(description.localizedInterfaceText)
        #endif
    }

    private var regularTile: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .toolPouchIcon(.small, weight: .medium)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(theme.colors.primaryAccent.color)

                Text(title.localizedInterfaceText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let badgeValue {
                    countBadge(badgeValue)
                }
            }

            Text(description.localizedInterfaceText)
                .font(.caption2)
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
        .accessibilityLabel(title.localizedInterfaceText)
        .accessibilityHint(accessibilityHint)
        #if os(macOS)
        .help(description.localizedInterfaceText)
        #endif
    }

    private var regularMinimumHeight: CGFloat {
        return supportedPlatforms == nil
            ? ToolPouchLayout.Tile.minimumHeight
            : ToolPouchLayout.Tile.minimumHeightWithPlatforms
    }

    private func countBadge(_ value: Int) -> some View {
        Text(value.formatted())
            .font(.caption2.monospacedDigit().weight(.bold))
            .foregroundStyle(theme.colors.primaryAccent.color)
            .padding(.horizontal, 7)
            .frame(minWidth: 24, minHeight: 24)
            .background(
                theme.colors.accentButtonBackground.color,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(theme.colors.primaryAccent.color.opacity(0.3), lineWidth: 1)
            }
            .accessibilityLabel("\(value) tools")
    }

    private func compactCountBadge(_ value: Int) -> some View {
        Text(value.formatted())
            .font(.caption2.monospacedDigit().weight(.bold))
            .foregroundStyle(theme.colors.primaryAccent.color)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(
                theme.colors.accentButtonBackground.color,
                in: Capsule()
            )
            .accessibilityLabel("\(value) tools")
    }

    private var accessibilityHint: String {
        guard let badgeValue else { return description.localizedInterfaceText }
        let toolCount = String(localized: "\(badgeValue) tools")
        return "\(description.localizedInterfaceText) \(toolCount)."
    }
}
