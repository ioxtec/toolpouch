import SwiftUI

struct ToolCategoryView: View {
    let category: ToolCategory

    var body: some View {
        ContentUnavailableView(
            "No Tools Yet",
            systemImage: category.systemImage,
            description: Text(
                "Tools in the \(category.title) category will appear here."
            )
        )
        .navigationTitle(category.title)
    }
}
