import SwiftUI

struct DashboardView: View {
    private let categories: [ToolCategory]
    private let availableTools: [ToolDefinition]
    private let quickAccessPreferences: QuickAccessPreferences
    private let selectTool: (ToolDefinition) -> Void

    init(
        categories: [ToolCategory],
        availableTools: [ToolDefinition],
        quickAccessPreferences: QuickAccessPreferences,
        selectTool: @escaping (ToolDefinition) -> Void
    ) {
        self.categories = categories
        self.availableTools = availableTools
        self.quickAccessPreferences = quickAccessPreferences
        self.selectTool = selectTool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Tools",
                    subtitle: "Useful tools for everyday tasks."
                )

                DashboardSectionTitle("Quick Access")
                QuickAccessBar(
                    availableTools: availableTools,
                    savedToolIDs: quickAccessPreferences.toolIDs,
                    maximumCount: quickAccessPreferences.maximumCount,
                    selectTool: selectTool,
                    save: quickAccessPreferences.save
                )

                DashboardSectionTitle("Sections")
                AdaptiveGlassGrid {
                    ForEach(categories) { category in
                        NavigationLink(value: AppRoute.category(category.id)) {
                            ToolTile(
                                title: category.title,
                                description: category.description,
                                systemImage: category.systemImage
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .scrollIndicators(.never)
    }
}

private struct DashboardSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
