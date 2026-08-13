import SwiftUI

struct ThreeColumnToolNavigationView: View {
    @Environment(\.appTheme) private var theme

    let dependencies: AppDependencies

    @State private var selectedCategoryID: ToolCategory.ID?
    @State private var selectedToolID: ToolDefinition.ID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private let quickAccessHeaderHeight: CGFloat = 45

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
        navigation
            .overlay(alignment: .top) {
                quickAccessHeader
            }
    }

    private var quickAccessHeader: some View {
        VStack(spacing: 0) {
            QuickAccessBar(
                availableTools: dependencies.toolRegistry.tools(for: .current),
                savedToolIDs: dependencies.quickAccessPreferences.toolIDs,
                maximumCount: dependencies.quickAccessPreferences.maximumCount,
                selectTool: select,
                save: dependencies.quickAccessPreferences.save,
                density: .compact
            )
            .padding(.horizontal, ToolPouchLayout.Content.padding)
            .padding(.vertical, 5)
            .background(theme.colors.elevatedSurface.color)

            Divider()
        }
        .frame(height: quickAccessHeaderHeight)
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
            .padding(.top, quickAccessHeaderHeight)
            .scrollContentBackground(.hidden)
            .background(theme.colors.surface.color)
        } content: {
            Group {
                if let category = selectedCategory {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(tools) { tool in
                                Button {
                                    selectedToolID = tool.id
                                } label: {
                                    ToolTile(
                                        title: tool.title,
                                        description: tool.description,
                                        systemImage: tool.systemImage,
                                        supportedPlatforms: tool.supportedPlatforms,
                                        density: .compact,
                                        isSelected: selectedToolID == tool.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                    }
                    .navigationTitle(category.title)
                    .background(theme.colors.elevatedSurface.color)
                } else {
                    ContentUnavailableView(
                        "Choose a Section",
                        systemImage: "square.grid.2x2"
                    )
                }
            }
            .padding(.top, quickAccessHeaderHeight)
            .navigationSplitViewColumnWidth(min: 230, ideal: 290)
        } detail: {
            detail
                .padding(.top, quickAccessHeaderHeight)
                .background(theme.colors.background.color)
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
