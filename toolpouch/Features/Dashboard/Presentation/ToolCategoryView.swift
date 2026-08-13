import SwiftUI

struct ToolCategoryView: View {
    let category: ToolCategory
    let tools: [ToolDefinition]
    let density: ToolPouchContentDensity

    init(
        category: ToolCategory,
        tools: [ToolDefinition],
        density: ToolPouchContentDensity = .regular
    ) {
        self.category = category
        self.tools = tools
        self.density = density
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: density == .compact
                    ? ToolPouchLayout.MenuBar.contentSpacing
                    : ToolPouchLayout.Content.spacing
            ) {
                ScreenHeader(
                    title: category.title,
                    subtitle: category.description,
                    density: density
                )

                if tools.isEmpty {
                    ContentUnavailableView(
                        "No Tools Yet",
                        systemImage: category.systemImage,
                        description: Text(
                            "Tools in this section will appear here."
                        )
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    AdaptiveGlassGrid(
                        spacing: density == .compact
                            ? ToolPouchLayout.MenuBar.gridSpacing
                            : ToolPouchLayout.Grid.spacing
                    ) {
                        ForEach(tools) { tool in
                            NavigationLink(value: AppRoute.tool(tool.id)) {
                                ToolTile(
                                    title: tool.title,
                                    description: tool.description,
                                    systemImage: tool.systemImage,
                                    supportedPlatforms: tool.supportedPlatforms,
                                    density: density
                                )
                            }
                            .buttonStyle(.plain)
                        }
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
}
