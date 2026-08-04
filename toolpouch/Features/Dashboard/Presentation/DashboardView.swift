import SwiftUI

struct DashboardView: View {
    private let categories: [ToolCategory]

    init(categories: [ToolCategory] = ToolCatalog.categories) {
        self.categories = categories
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Tools",
                    subtitle: "A growing collection of focused developer utilities."
                )

                AdaptiveGlassGrid {
                    ForEach(categories) { category in
                        NavigationLink(value: AppRoute.category(category)) {
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
        .navigationTitle("ToolPouch")
    }
}
