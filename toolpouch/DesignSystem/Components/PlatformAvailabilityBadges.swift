import SwiftUI

struct PlatformAvailabilityBadges: View {
    @Environment(\.appTheme) private var theme

    let platforms: Set<ToolPlatform>
    let compact: Bool

    init(platforms: Set<ToolPlatform>, compact: Bool = false) {
        self.platforms = platforms
        self.compact = compact
    }

    private var sortedPlatforms: [ToolPlatform] {
        ToolPlatform.allCases.filter(platforms.contains)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !compact {
                HStack(spacing: 5) {
                    badges(showsText: true)
                }
            }

            HStack(spacing: 5) {
                badges(showsText: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private func badges(showsText: Bool) -> some View {
        ForEach(sortedPlatforms, id: \.self) { platform in
            HStack(spacing: 4) {
                Image(systemName: platform.systemImage)
                    .toolPouchIcon(.small)
                if showsText {
                    Text(platform.displayName)
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(theme.colors.secondaryText.color)
            .padding(.horizontal, compact ? 6 : 7)
            .padding(.vertical, compact ? 3 : 4)
            .background(theme.colors.elevatedSurface.color, in: .capsule)
        }
    }

    private var accessibilityDescription: String {
        "Available on " + sortedPlatforms.map(\.displayName).joined(separator: ", ")
    }
}
