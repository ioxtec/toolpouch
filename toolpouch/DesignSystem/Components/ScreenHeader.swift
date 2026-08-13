import SwiftUI

struct ScreenHeader: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let subtitle: String
    let density: ToolPouchContentDensity

    init(
        title: String,
        subtitle: String,
        density: ToolPouchContentDensity = .regular
    ) {
        self.title = title
        self.subtitle = subtitle
        self.density = density
    }

    var body: some View {
        VStack(alignment: .leading, spacing: density == .compact ? 1 : 4) {
            Text(title)
                .font(
                    density == .compact
                        ? .headline
                        : .title2.weight(.semibold)
                )
                .foregroundStyle(theme.colors.primaryText.color)

            Text(subtitle)
                .font(density == .compact ? .caption : .subheadline)
                .foregroundStyle(theme.colors.secondaryText.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
