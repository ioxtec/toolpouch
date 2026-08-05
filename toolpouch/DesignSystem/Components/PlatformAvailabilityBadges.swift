import SwiftUI

struct PlatformAvailabilityBadges: View {
    let platforms: Set<ToolPlatform>

    private var sortedPlatforms: [ToolPlatform] {
        ToolPlatform.allCases.filter(platforms.contains)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) {
                badges(showsText: true)
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
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.12), in: .capsule)
        }
    }

    private var accessibilityDescription: String {
        "Available on " + sortedPlatforms.map(\.displayName).joined(separator: ", ")
    }
}
