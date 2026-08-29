import SwiftUI

struct ToolSearchField: View {
    @Environment(\.appTheme) private var theme
    @Binding var query: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .toolPouchIcon(.small, weight: .medium)
                .foregroundStyle(theme.colors.secondaryText.color)

            TextField("Search tools", text: $query)
                .textFieldStyle(.plain)
                .font(.subheadline)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .toolPouchIcon(.small)
                        .foregroundStyle(theme.colors.secondaryText.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .toolPouchSurface(elevated: true, cornerRadius: 999)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }
}

struct ToolSearchResultsView: View {
    @Environment(\.appTheme) private var theme

    let query: String
    let tools: [ToolDefinition]
    let categories: [ToolCategory]
    let selectTool: (ToolDefinition) -> Void

    private var results: [ToolDefinition] {
        let terms = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)

        guard !terms.isEmpty else { return [] }

        return tools.filter { tool in
            let category = categories.first { $0.id == tool.categoryID }
            let searchableText = [
                tool.title,
                tool.description,
                category?.title ?? "",
            ].joined(separator: " ")

            return terms.allSatisfy {
                searchableText.localizedCaseInsensitiveContains($0)
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .frame(maxWidth: .infinity, minHeight: 210)
                } else {
                    ForEach(results) { tool in
                        Button {
                            selectTool(tool)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: tool.systemImage)
                                    .toolPouchIcon(.medium, weight: .medium)
                                    .foregroundStyle(theme.colors.primaryAccent.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(tool.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(theme.colors.primaryText.color)

                                    Text(resultSubtitle(for: tool))
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.secondaryText.color)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .toolPouchIcon(.small, weight: .semibold)
                                    .foregroundStyle(theme.colors.secondaryText.color)
                            }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                            .contentShape(.capsule)
                            .toolPouchSurface(interactive: true, cornerRadius: 999)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(tool.description)
                    }
                }
            }
            .padding(.horizontal, ToolPouchLayout.MenuBar.contentPadding)
            .padding(.vertical, 5)
        }
        .scrollIndicators(.never)
    }

    private func resultSubtitle(for tool: ToolDefinition) -> String {
        let categoryName = categories.first { $0.id == tool.categoryID }?.title
        return [categoryName, tool.description]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
