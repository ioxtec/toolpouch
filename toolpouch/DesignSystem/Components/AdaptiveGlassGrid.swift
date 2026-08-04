import SwiftUI

struct AdaptiveGlassGrid<Content: View>: View {
    private let minimumItemWidth: CGFloat
    private let spacing: CGFloat
    private let content: Content

    init(
        minimumItemWidth: CGFloat = ToolPouchLayout.Grid.minimumItemWidth,
        spacing: CGFloat = ToolPouchLayout.Grid.spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = minimumItemWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            LazyVGrid(columns: columns, spacing: spacing) {
                content
            }
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: minimumItemWidth),
                spacing: spacing,
                alignment: .top
            ),
        ]
    }
}
