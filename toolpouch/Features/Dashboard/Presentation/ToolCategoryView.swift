import SwiftUI

struct ToolCategoryView: View {
    let category: ToolCategory
    let tools: [ToolDefinition]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: category.title,
                    subtitle: category.description
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
                    AdaptiveGlassGrid {
                        ForEach(tools) { tool in
                            NavigationLink(value: AppRoute.tool(tool.id)) {
                                ToolTile(
                                    title: tool.title,
                                    description: tool.description,
                                    systemImage: tool.systemImage,
                                    supportedPlatforms: tool.supportedPlatforms
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .scrollIndicators(.never)
    }
}
