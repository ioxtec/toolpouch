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

            if let badgeValue {
                countBadge(badgeValue)
            }
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
        .accessibilityHint(accessibilityHint)
    }

    private var regularTile: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .toolPouchIcon(.small, weight: .medium)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(theme.colors.primaryAccent.color)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let badgeValue {
                    countBadge(badgeValue)
                }
            }

            Text(description)
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
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
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
                theme.colors.primaryAccent.color.opacity(isHovering ? 0.22 : 0.14),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(theme.colors.primaryAccent.color.opacity(0.3), lineWidth: 1)
            }
            .accessibilityLabel("\(value) tools")
    }

    private var accessibilityHint: String {
        guard let badgeValue else { return description }
        return "\(description) \(badgeValue) tools."
    }
}
