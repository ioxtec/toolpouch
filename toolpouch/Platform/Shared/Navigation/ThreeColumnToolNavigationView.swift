import SwiftUI

struct ThreeColumnToolNavigationView: View {
    let dependencies: AppDependencies

    @State private var selectedCategoryID: ToolCategory.ID?
    @State private var selectedToolID: ToolDefinition.ID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var categories: [ToolCategory] {
        dependencies.toolRegistry.categories(for: .current)
    }

    private var tools: [ToolDefinition] {
        guard let selectedCategoryID else { return [] }
        return dependencies.toolRegistry.tools(
            in: selectedCategoryID,
            for: .current
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            QuickAccessBar(
                availableTools: dependencies.toolRegistry.tools(for: .current),
                savedToolIDs: dependencies.quickAccessPreferences.toolIDs,
                maximumCount: dependencies.quickAccessPreferences.maximumCount,
                selectTool: select,
                save: dependencies.quickAccessPreferences.save
            )
            .padding(.horizontal, ToolPouchLayout.Content.padding)
            .padding(.vertical, 6)

            Divider()

            navigation
        }
    }

    private var navigation: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedCategoryID) {
                Section("Sections") {
                    ForEach(categories) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .tag(category.id)
                    }
                }
            }
            .navigationTitle("ToolPouch")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } content: {
            Group {
                if let category = selectedCategory {
                    List(tools, selection: $selectedToolID) { tool in
                        ToolListRow(tool: tool)
                            .tag(tool.id)
                    }
                    .navigationTitle(category.title)
                } else {
                    ContentUnavailableView(
                        "Choose a Section",
                        systemImage: "square.grid.2x2"
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 230, ideal: 290)
        } detail: {
            detail
        }
        .onChange(of: selectedCategoryID) {
            if !tools.contains(where: { $0.id == selectedToolID }) {
                selectedToolID = tools.first?.id
            }
        }
        .task {
            if selectedCategoryID == nil {
                selectedCategoryID = categories.first?.id
                selectedToolID = tools.first?.id
            }
        }
    }

    private var selectedCategory: ToolCategory? {
        guard let selectedCategoryID else { return nil }
        return dependencies.toolRegistry.category(id: selectedCategoryID)
    }

    private func select(_ tool: ToolDefinition) {
        selectedCategoryID = tool.categoryID
        selectedToolID = tool.id
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedToolID,
           let destination = dependencies.toolRegistry.destination(
               for: selectedToolID,
               dependencies: dependencies
           ) {
            destination
                .navigationTitle(
                    dependencies.toolRegistry.tool(id: selectedToolID)?.title ?? "Tool"
                )
        } else {
            ContentUnavailableView(
                "Choose a Tool",
                systemImage: "wrench.and.screwdriver",
                description: Text("Select a tool from the middle column.")
            )
        }
    }
}

private struct ToolListRow: View {
    let tool: ToolDefinition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.systemImage)
                .toolPouchIcon(.medium)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.title)
                    .font(.headline)
                Text(tool.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                PlatformAvailabilityBadges(
                    platforms: tool.supportedPlatforms
                )
            }
        }
        .padding(.vertical, 4)
    }
}
