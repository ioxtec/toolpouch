import SwiftUI

struct DashboardView: View {
    private let categories: [ToolCategory]
    private let availableTools: [ToolDefinition]
    private let quickAccessPreferences: QuickAccessPreferences
    private let selectTool: (ToolDefinition) -> Void
    private let density: ToolPouchContentDensity

    init(
        categories: [ToolCategory],
        availableTools: [ToolDefinition],
        quickAccessPreferences: QuickAccessPreferences,
        density: ToolPouchContentDensity = .regular,
        selectTool: @escaping (ToolDefinition) -> Void
    ) {
        self.categories = categories
        self.availableTools = availableTools
        self.quickAccessPreferences = quickAccessPreferences
        self.density = density
        self.selectTool = selectTool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: contentSpacing) {
                ScreenHeader(
                    title: "Tools",
                    subtitle: "Useful tools for everyday tasks.",
                    density: density
                )

                DashboardSectionTitle("Quick Access", density: density)
                QuickAccessBar(
                    availableTools: availableTools,
                    savedToolIDs: quickAccessPreferences.toolIDs,
                    maximumCount: quickAccessPreferences.maximumCount,
                    selectTool: selectTool,
                    save: quickAccessPreferences.save,
                    density: density
                )

                DashboardSectionTitle("Sections", density: density)
                AdaptiveGlassGrid(
                    spacing: density == .compact
                        ? ToolPouchLayout.MenuBar.gridSpacing
                        : ToolPouchLayout.Grid.spacing
                ) {
                    ForEach(categories) { category in
                        NavigationLink(value: AppRoute.category(category.id)) {
                            ToolTile(
                                title: category.title,
                                description: category.description,
                                systemImage: category.systemImage,
                                density: density
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(
                density == .compact
                    ? ToolPouchLayout.MenuBar.contentPadding
                    : ToolPouchLayout.Content.padding
            )
        }
        .scrollIndicators(.never)
    }

    private var contentSpacing: CGFloat {
        density == .compact
            ? ToolPouchLayout.MenuBar.contentSpacing
            : ToolPouchLayout.Content.spacing
    }
}

private struct DashboardSectionTitle: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let density: ToolPouchContentDensity

    init(
        _ title: String,
        density: ToolPouchContentDensity = .regular
    ) {
        self.title = title
        self.density = density
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(density == .compact ? .subheadline.weight(.semibold) : .headline)

            Rectangle()
                .fill(theme.colors.border.color.opacity(0.65))
                .frame(height: 1)
        }
        .foregroundStyle(theme.colors.primaryText.color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
