import SwiftData
import SwiftUI

struct QuickCopyNotesView: View {
    private enum Screen: Equatable {
        case folders
        case collections(folderID: UUID)
        case snippets(folderID: UUID, collectionID: UUID)
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [QuickCopyFolderRecord]

    @State private var screen = Screen.folders
    @State private var editorRequest: QuickCopyEditorRequest?
    @State private var deletionRequest: QuickCopyDeletionRequest?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if !breadcrumbTrail.isEmpty {
                breadcrumb
            }
            header
            Divider()
            content
        }
        .sheet(item: $editorRequest) { request in
            editor(for: request)
        }
        .alert(
            deletionRequest?.title ?? "Delete Item?",
            isPresented: Binding(
                get: { deletionRequest != nil },
                set: { if !$0 { deletionRequest = nil } }
            ),
            presenting: deletionRequest
        ) { request in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                delete(request)
            }
        } message: { request in
            Text(request.message)
        }
        .onChange(of: folders.count) {
            repairNavigationIfNeeded()
        }
    }

    private var sortedFolders: [QuickCopyFolderRecord] {
        folders.sorted(by: quickCopyFolderComesBefore)
    }

    private var selectedFolder: QuickCopyFolderRecord? {
        let folderID: UUID
        switch screen {
        case .folders:
            return nil
        case let .collections(id), let .snippets(id, _):
            folderID = id
        }
        return folders.first { $0.id == folderID }
    }

    private var selectedCollection: QuickCopyCollectionRecord? {
        guard case let .snippets(_, collectionID) = screen else { return nil }
        return selectedFolder?.collections?.first { $0.id == collectionID }
    }

    private struct BreadcrumbItem {
        let title: String
        let action: (() -> Void)?
    }

    private var breadcrumbTrail: [BreadcrumbItem] {
        switch screen {
        case .folders:
            return []
        case .collections:
            return [
                BreadcrumbItem(title: "Quick Copy Notes", action: { screen = .folders }),
                BreadcrumbItem(title: selectedFolder?.title ?? "Folder", action: nil)
            ]
        case let .snippets(folderID, _):
            return [
                BreadcrumbItem(title: "Quick Copy Notes", action: { screen = .folders }),
                BreadcrumbItem(
                    title: selectedFolder?.title ?? "Folder",
                    action: { screen = .collections(folderID: folderID) }
                ),
                BreadcrumbItem(title: selectedCollection?.title ?? "Collection", action: nil)
            ]
        }
    }

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(breadcrumbTrail.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if let action = item.action {
                        Button(action: action) {
                            Text(item.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(item.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, ToolPouchLayout.Content.padding)
        }
        .padding(.top, 8)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if screen != .folders {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .toolPouchIcon(.medium, weight: .semibold)
                }
                .buttonStyle(.borderless)
                .help("Back")
                .accessibilityLabel("Back")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: presentNewEditor) {
                Image(systemName: "plus")
                    .toolPouchIcon(.medium, weight: .semibold)
            }
            .buttonStyle(.glassProminent)
            .help(addButtonLabel)
            .accessibilityLabel(addButtonLabel)
        }
        .padding(ToolPouchLayout.Content.padding)
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            VStack(spacing: 10) {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Dismiss") { self.errorMessage = nil }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }

        switch screen {
        case .folders:
            foldersContent
        case .collections:
            collectionsContent
        case .snippets:
            snippetsContent
        }
    }

    @ViewBuilder
    private var foldersContent: some View {
        if sortedFolders.isEmpty {
            QuickCopyEmptyView(
                title: "No Folders",
                description: "Create a folder such as Work, Personal, or Servers.",
                systemImage: "folder.badge.plus",
                buttonTitle: "Create Folder",
                action: presentNewEditor
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sortedFolders) { folder in
                        QuickCopyNavigationCard(
                            title: folder.title,
                            details: folder.details,
                            countText: itemCount(
                                folder.collections?.count ?? 0,
                                singular: "collection",
                                plural: "collections"
                            ),
                            systemImage: "folder.fill",
                            open: {
                                screen = .collections(folderID: folder.id)
                            },
                            edit: {
                                editorRequest = QuickCopyEditorRequest(
                                    content: .folder(folder)
                                )
                            },
                            delete: {
                                deletionRequest = .folder(folder)
                            }
                        )
                    }
                }
                .padding(ToolPouchLayout.Content.padding)
            }
        }
    }

    @ViewBuilder
    private var collectionsContent: some View {
        if let folder = selectedFolder {
            let collections = (folder.collections ?? []).sorted(
                by: quickCopyCollectionComesBefore
            )
            if collections.isEmpty {
                QuickCopyEmptyView(
                    title: "No Collections",
                    description: "Collections keep related notes together inside this folder.",
                    systemImage: "rectangle.stack.badge.plus",
                    buttonTitle: "Create Collection",
                    action: presentNewEditor
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(collections) { collection in
                            QuickCopyNavigationCard(
                                title: collection.title,
                                details: collection.details,
                                countText: itemCount(
                                    collection.snippets?.count ?? 0,
                                    singular: "note",
                                    plural: "notes"
                                ),
                                systemImage: "rectangle.stack.fill",
                                open: {
                                    screen = .snippets(
                                        folderID: folder.id,
                                        collectionID: collection.id
                                    )
                                },
                                edit: {
                                    editorRequest = QuickCopyEditorRequest(
                                        content: .collection(
                                            folder: folder,
                                            collection: collection
                                        )
                                    )
                                },
                                delete: {
                                    deletionRequest = .collection(collection)
                                }
                            )
                        }
                    }
                    .padding(ToolPouchLayout.Content.padding)
                }
            }
        } else {
            missingSelectionView
        }
    }

    @ViewBuilder
    private var snippetsContent: some View {
        if let collection = selectedCollection {
            let snippets = (collection.snippets ?? []).sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite && !$1.isFavorite
                }
                return quickCopyComesBefore($0, $1)
            }
            if snippets.isEmpty {
                QuickCopyEmptyView(
                    title: "No Notes",
                    description: "Add a command, address, message, or any text you copy often.",
                    systemImage: "doc.badge.plus",
                    buttonTitle: "Create Note",
                    action: presentNewEditor
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(snippets) { snippet in
                            QuickCopySnippetCard(
                                snippet: snippet,
                                toggleFavorite: { toggleFavorite(snippet) },
                                edit: {
                                    editorRequest = QuickCopyEditorRequest(
                                        content: .snippet(
                                            collection: collection,
                                            snippet: snippet
                                        )
                                    )
                                },
                                delete: {
                                    deletionRequest = .snippet(snippet)
                                }
                            )
                        }
                    }
                    .padding(ToolPouchLayout.Content.padding)
                }
            }
        } else {
            missingSelectionView
        }
    }

    private var missingSelectionView: some View {
        ContentUnavailableView(
            "Item Not Found",
            systemImage: "questionmark.folder",
            description: Text("It may have been removed on another device.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func editor(for request: QuickCopyEditorRequest) -> some View {
        switch request.content {
        case let .folder(folder):
            QuickCopyFolderEditor(
                folder: folder,
                nextSortOrder: nextFolderSortOrder
            )
        case let .collection(folder, collection):
            QuickCopyCollectionEditor(
                folder: folder,
                collection: collection,
                nextSortOrder: nextCollectionSortOrder(in: folder)
            )
        case let .snippet(collection, snippet):
            QuickCopySnippetEditor(
                collection: collection,
                snippet: snippet,
                nextSortOrder: nextSnippetSortOrder(in: collection)
            )
        }
    }

    private var headerTitle: String {
        switch screen {
        case .folders:
            "Quick Copy Notes"
        case .collections:
            selectedFolder?.title ?? "Folder"
        case .snippets:
            selectedCollection?.title ?? "Collection"
        }
    }

    private var headerSubtitle: String {
        switch screen {
        case .folders:
            "Keep frequently copied text organized and ready."
        case .collections:
            "Choose a collection or create a new one."
        case .snippets:
            "Copy a complete note with one click."
        }
    }

    private var addButtonLabel: String {
        switch screen {
        case .folders: "Add Folder"
        case .collections: "Add Collection"
        case .snippets: "Add Note"
        }
    }

    private func presentNewEditor() {
        switch screen {
        case .folders:
            editorRequest = QuickCopyEditorRequest(content: .folder(nil))
        case .collections:
            guard let selectedFolder else { return }
            editorRequest = QuickCopyEditorRequest(
                content: .collection(folder: selectedFolder, collection: nil)
            )
        case .snippets:
            guard let selectedCollection else { return }
            editorRequest = QuickCopyEditorRequest(
                content: .snippet(collection: selectedCollection, snippet: nil)
            )
        }
    }

    private func goBack() {
        switch screen {
        case .folders:
            break
        case .collections:
            screen = .folders
        case let .snippets(folderID, _):
            screen = .collections(folderID: folderID)
        }
    }

    private func toggleFavorite(_ snippet: QuickCopySnippetRecord) {
        snippet.isFavorite.toggle()
        snippet.updatedAt = Date()
        saveChanges(errorMessage: "The favorite could not be updated.")
    }

    private func delete(_ request: QuickCopyDeletionRequest) {
        switch request.target {
        case let .folder(folder):
            modelContext.delete(folder)
            screen = .folders
        case let .collection(collection):
            let folderID = collection.folder?.id
            modelContext.delete(collection)
            if let folderID {
                screen = .collections(folderID: folderID)
            } else {
                screen = .folders
            }
        case let .snippet(snippet):
            modelContext.delete(snippet)
        }
        saveChanges(errorMessage: "The item could not be deleted.")
        deletionRequest = nil
    }

    private func saveChanges(errorMessage: String) {
        do {
            try modelContext.save()
        } catch {
            self.errorMessage = errorMessage
        }
    }

    private func repairNavigationIfNeeded() {
        switch screen {
        case .folders:
            break
        case .collections:
            if selectedFolder == nil { screen = .folders }
        case let .snippets(folderID, _):
            if selectedFolder == nil {
                screen = .folders
            } else if selectedCollection == nil {
                screen = .collections(folderID: folderID)
            }
        }
    }

    private func itemCount(
        _ count: Int,
        singular: String,
        plural: String
    ) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private var nextFolderSortOrder: Int {
        (folders.map(\.sortOrder).max() ?? -1) + 1
    }

    private func nextCollectionSortOrder(
        in folder: QuickCopyFolderRecord
    ) -> Int {
        ((folder.collections ?? []).map(\.sortOrder).max() ?? -1) + 1
    }

    private func nextSnippetSortOrder(
        in collection: QuickCopyCollectionRecord
    ) -> Int {
        ((collection.snippets ?? []).map(\.sortOrder).max() ?? -1) + 1
    }
}

private struct QuickCopyNavigationCard: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let details: String
    let countText: String
    let systemImage: String
    let open: () -> Void
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: open) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .toolPouchIcon(.medium)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(countText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if !details.isEmpty {
                            Text(details)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .toolPouchIcon(.small, weight: .semibold)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            #if os(watchOS)
            Button(action: edit) {
                Image(systemName: "pencil")
                    .toolPouchIcon(.small)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit \(title)")
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .toolPouchIcon(.small)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete \(title)")
            #else
            Menu {
                Button("Edit", systemImage: "pencil", action: edit)
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .toolPouchIcon(.medium)
            }
            .accessibilityLabel("Actions for \(title)")
            #endif
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.colors.interactiveSurface.color, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuickCopySnippetCard: View {
    @Environment(\.appTheme) private var theme

    let snippet: QuickCopySnippetRecord
    let toggleFavorite: () -> Void
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(snippet.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if !snippet.details.isEmpty {
                    Text(snippet.details)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: toggleFavorite) {
                    Image(systemName: snippet.isFavorite ? "star.fill" : "star")
                        .toolPouchIcon(.small)
                        .foregroundStyle(snippet.isFavorite ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help(snippet.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                .accessibilityLabel(snippet.isFavorite ? "Remove from Favorites" : "Add to Favorites")

                #if os(watchOS)
                Button(action: edit) {
                    Image(systemName: "pencil")
                        .toolPouchIcon(.small)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(snippet.title)")
                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                        .toolPouchIcon(.small)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete \(snippet.title)")
                #else
                Menu {
                    Button("Edit", systemImage: "pencil", action: edit)
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive, action: delete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .toolPouchIcon(.small)
                }
                .accessibilityLabel("Actions for \(snippet.title)")
                #endif
            }

            HStack(alignment: .top, spacing: 8) {
                Text(snippet.content)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(4)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    #if !os(watchOS)
                    .textSelection(.enabled)
                    #endif

                #if !os(watchOS)
                CopyButton(value: snippet.content)
                #endif
            }
            .padding(8)
            .background(theme.colors.elevatedSurface.color, in: RoundedRectangle(cornerRadius: 8))

            #if os(watchOS)
            Text("Open this note on iPhone or Mac to copy it.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            #endif
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.interactiveSurface.color, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuickCopyEmptyView: View {
    let title: String
    let description: String
    let systemImage: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            Button(buttonTitle, action: action)
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct QuickCopyDeletionRequest: Identifiable {
    enum Target {
        case folder(QuickCopyFolderRecord)
        case collection(QuickCopyCollectionRecord)
        case snippet(QuickCopySnippetRecord)
    }

    let id = UUID()
    let target: Target
    let title: String
    let message: String

    static func folder(_ folder: QuickCopyFolderRecord) -> Self {
        Self(
            target: .folder(folder),
            title: "Delete \"\(folder.title)\"?",
            message: "All collections and notes inside this folder will also be deleted."
        )
    }

    static func collection(_ collection: QuickCopyCollectionRecord) -> Self {
        Self(
            target: .collection(collection),
            title: "Delete \"\(collection.title)\"?",
            message: "All notes inside this collection will also be deleted."
        )
    }

    static func snippet(_ snippet: QuickCopySnippetRecord) -> Self {
        Self(
            target: .snippet(snippet),
            title: "Delete \"\(snippet.title)\"?",
            message: "This note will be permanently deleted."
        )
    }
}

private func quickCopyFolderComesBefore(
    _ lhs: QuickCopyFolderRecord,
    _ rhs: QuickCopyFolderRecord
) -> Bool {
    if lhs.sortOrder != rhs.sortOrder {
        return lhs.sortOrder < rhs.sortOrder
    }
    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
}

private func quickCopyCollectionComesBefore(
    _ lhs: QuickCopyCollectionRecord,
    _ rhs: QuickCopyCollectionRecord
) -> Bool {
    if lhs.sortOrder != rhs.sortOrder {
        return lhs.sortOrder < rhs.sortOrder
    }
    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
}

private func quickCopyComesBefore(
    _ lhs: QuickCopySnippetRecord,
    _ rhs: QuickCopySnippetRecord
) -> Bool {
    if lhs.sortOrder != rhs.sortOrder {
        return lhs.sortOrder < rhs.sortOrder
    }
    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
}
