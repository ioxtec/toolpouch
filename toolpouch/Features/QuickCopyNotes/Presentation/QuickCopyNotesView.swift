import SwiftData
import SwiftUI

struct QuickCopyNotesView: View {
    private enum Screen: Equatable {
        case collections
        case snippets(folderID: UUID, collectionID: UUID)
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [QuickCopyFolderRecord]

    @AppStorage(AppPreferenceKey.quickCopySelectedFolderID)
    private var storedFolderID = ""

    @State private var screen = Screen.collections
    @State private var editorRequest: QuickCopyEditorRequest?
    @State private var deletionRequest: QuickCopyDeletionRequest?
    @State private var errorMessage: String?
    @State private var expandedFolderIDs: Set<UUID> = []
    @State private var knownFolderIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            header
            if case .snippets = screen {
                collectionContext
            }
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
            synchronizeExpandedFolders()
        }
        .onAppear {
            repairNavigationIfNeeded()
            synchronizeExpandedFolders()
        }
    }

    private var sortedFolders: [QuickCopyFolderRecord] {
        folders.sorted(by: quickCopyFolderComesBefore)
    }

    private var selectedFolder: QuickCopyFolderRecord? {
        switch screen {
        case .collections:
            if let folderID = UUID(uuidString: storedFolderID),
               let folder = folders.first(where: { $0.id == folderID }) {
                return folder
            }
            return sortedFolders.first
        case let .snippets(id, _):
            return folders.first { $0.id == id }
        }
    }

    private var selectedCollection: QuickCopyCollectionRecord? {
        guard case let .snippets(_, collectionID) = screen else { return nil }
        return selectedFolder?.collections?.first { $0.id == collectionID }
    }

    private var header: some View {
        ScreenHeader(title: headerTitle, subtitle: headerSubtitle)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ToolPouchLayout.Content.padding)
    }

    @ViewBuilder
    private var collectionContext: some View {
        if let folder = selectedFolder, let collection = selectedCollection {
            HStack(spacing: 10) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .toolPouchIcon(.medium, weight: .semibold)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .toolPouchCircleSurface()
                .help("Back to Collections")
                .accessibilityLabel("Back to Collections")

                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.title)
                        .font(ToolPouchLayout.Typography.sectionTitle)
                        .lineLimit(1)
                    Label(folder.title, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                ToolPouchActionMenu(
                    accessibilityLabel: "Collection actions",
                    actions: collectionActions(collection, in: folder)
                )
            }
            .padding(.horizontal, ToolPouchLayout.Content.padding)
            .padding(.bottom, ToolPouchLayout.Content.padding)
        }
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
        case .collections:
            collectionsContent
        case .snippets:
            snippetsContent
        }
    }

    @ViewBuilder
    private var collectionsContent: some View {
        if sortedFolders.isEmpty {
            QuickCopyEmptyView(
                title: "No Folders",
                description: "Create a folder such as Work, Personal, or Servers.",
                systemImage: "folder.badge.plus",
                buttonTitle: "Add Folder",
                action: {
                    editorRequest = QuickCopyEditorRequest(content: .folder(nil))
                }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: ToolPouchLayout.Spacing.small) {
                    ForEach(sortedFolders) { folder in
                        QuickCopyFolderTreeSection(
                            folder: folder,
                            isExpanded: Binding(
                                get: { expandedFolderIDs.contains(folder.id) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedFolderIDs.insert(folder.id)
                                    } else {
                                        expandedFolderIDs.remove(folder.id)
                                    }
                                }
                            ),
                            openCollection: { collection in
                                storedFolderID = folder.id.uuidString
                                screen = .snippets(
                                    folderID: folder.id,
                                    collectionID: collection.id
                                )
                            },
                            folderActions: folderActions(folder),
                            collectionActions: { collection in
                                collectionActions(collection, in: folder)
                            },
                            addCollection: {
                                editorRequest = QuickCopyEditorRequest(
                                    content: .collection(folder: folder, collection: nil)
                                )
                            }
                        )
                    }
                }
                .padding(ToolPouchLayout.Content.padding)
                .reportToolContentHeight(additionalHeight: 102)
            }
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
                    LazyVStack(spacing: 0) {
                        ForEach(Array(snippets.enumerated()), id: \.element.id) { index, snippet in
                            QuickCopySnippetRow(
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

                            if index < snippets.count - 1 {
                                Divider()
                                    .padding(.horizontal, ToolPouchLayout.Spacing.xLarge)
                            }
                        }
                    }
                    .toolPouchSurface(
                        elevated: true,
                        cornerRadius: ToolPouchLayout.Radius.card
                    )
                    .padding(ToolPouchLayout.Content.padding)
                    .reportToolContentHeight(additionalHeight: 102)
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
        "Quick Copy Notes"
    }

    private var headerSubtitle: String {
        switch screen {
        case .collections:
            "Choose a folder and open a collection."
        case .snippets:
            "Copy a complete note with one click."
        }
    }

    private func presentNewEditor() {
        switch screen {
        case .collections:
            guard let selectedFolder else {
                editorRequest = QuickCopyEditorRequest(content: .folder(nil))
                return
            }
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
        case .collections:
            break
        case let .snippets(folderID, _):
            storedFolderID = folderID.uuidString
            screen = .collections
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
            let replacement = sortedFolders.first { $0.id != folder.id }
            modelContext.delete(folder)
            storedFolderID = replacement?.id.uuidString ?? ""
            screen = .collections
        case let .collection(collection):
            let folderID = collection.folder?.id
            modelContext.delete(collection)
            if let folderID {
                storedFolderID = folderID.uuidString
                screen = .collections
            } else {
                screen = .collections
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
        case .collections:
            if let selectedFolder {
                let folderID = selectedFolder.id.uuidString
                if storedFolderID != folderID {
                    storedFolderID = folderID
                }
            } else if !storedFolderID.isEmpty {
                storedFolderID = ""
            }
        case let .snippets(folderID, _):
            if selectedFolder == nil {
                storedFolderID = sortedFolders.first?.id.uuidString ?? ""
                screen = .collections
            } else if selectedCollection == nil {
                storedFolderID = folderID.uuidString
                screen = .collections
            }
        }
    }

    /// New folders open automatically, while the user remains free to collapse
    /// any existing group. This keeps the tree useful without resetting their
    /// current navigation whenever SwiftData refreshes the query.
    private func synchronizeExpandedFolders() {
        let currentIDs = Set(folders.map(\.id))
        if knownFolderIDs.isEmpty {
            expandedFolderIDs = currentIDs
        } else {
            expandedFolderIDs.formUnion(currentIDs.subtracting(knownFolderIDs))
            expandedFolderIDs.formIntersection(currentIDs)
        }
        knownFolderIDs = currentIDs
    }

    private func folderActions(
        _ folder: QuickCopyFolderRecord
    ) -> [ToolPouchMenuAction] {
        [
            ToolPouchMenuAction("New Folder", systemImage: "folder.badge.plus") {
                editorRequest = QuickCopyEditorRequest(content: .folder(nil))
            },
            ToolPouchMenuAction("New Collection", systemImage: "rectangle.stack.badge.plus") {
                editorRequest = QuickCopyEditorRequest(
                    content: .collection(folder: folder, collection: nil)
                )
            },
            ToolPouchMenuAction("Edit Folder", systemImage: "pencil") {
                editorRequest = QuickCopyEditorRequest(content: .folder(folder))
            },
            ToolPouchMenuAction(
                "Delete Folder",
                systemImage: "trash",
                role: .destructive
            ) {
                deletionRequest = .folder(folder)
            }
        ]
    }

    private func collectionActions(
        _ collection: QuickCopyCollectionRecord,
        in folder: QuickCopyFolderRecord
    ) -> [ToolPouchMenuAction] {
        [
            ToolPouchMenuAction("New Note", systemImage: "doc.badge.plus") {
                editorRequest = QuickCopyEditorRequest(
                    content: .snippet(collection: collection, snippet: nil)
                )
            },
            ToolPouchMenuAction("Edit Collection", systemImage: "pencil") {
                editorRequest = QuickCopyEditorRequest(
                    content: .collection(folder: folder, collection: collection)
                )
            },
            ToolPouchMenuAction(
                "Delete Collection",
                systemImage: "trash",
                role: .destructive
            ) {
                deletionRequest = .collection(collection)
            }
        ]
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

private struct QuickCopyFolderTreeSection: View {
    @Environment(\.appTheme) private var theme

    let folder: QuickCopyFolderRecord
    @Binding var isExpanded: Bool
    let openCollection: (QuickCopyCollectionRecord) -> Void
    let folderActions: [ToolPouchMenuAction]
    let collectionActions: (QuickCopyCollectionRecord) -> [ToolPouchMenuAction]
    let addCollection: () -> Void

    @State private var isHovering = false

    private var collections: [QuickCopyCollectionRecord] {
        (folder.collections ?? []).sorted(by: quickCopyCollectionComesBefore)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            interactiveFolderHeader

            if isExpanded {
                if collections.isEmpty {
                    QuickCopyTreeAddRow(
                        title: "Add Collection",
                        action: addCollection
                    )
                } else {
                    ForEach(collections) { collection in
                        QuickCopyCollectionTreeRow(
                            collection: collection,
                            open: { openCollection(collection) },
                            actions: collectionActions(collection)
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var interactiveFolderHeader: some View {
#if os(macOS)
        folderHeader.onHover { isHovering = $0 }
#else
        folderHeader
#endif
    }

    private var folderHeader: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            Button(action: toggleExpansion) {
                Text(folder.title)
                    .font(ToolPouchLayout.Typography.supporting.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Text("\(collections.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)

            ToolPouchActionMenu(
                accessibilityLabel: String(format: "Actions for %@".localizedInterfaceText, folder.title),
                actions: folderActions
            )
            .opacity(showsActions ? 1 : 0)
            .allowsHitTesting(showsActions)

            Button(action: toggleExpansion) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .toolPouchIcon(.small, weight: .semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 24)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: (isExpanded ? "Collapse %@" : "Expand %@").localizedInterfaceText, folder.title))
        }
        .padding(.leading, 0)
        .padding(.trailing, 6)
        .frame(minHeight: 28)
        .background(
            theme.colors.recessedSurface.color.opacity(isHovering ? 0.7 : 0),
            in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
        )
    }

    private func toggleExpansion() {
        withAnimation(.snappy(duration: 0.18)) {
            isExpanded.toggle()
        }
    }

    private var showsActions: Bool {
#if os(macOS)
        isHovering
#else
        true
#endif
    }
}

private struct QuickCopyCollectionTreeRow: View {
    @Environment(\.appTheme) private var theme

    let collection: QuickCopyCollectionRecord
    let open: () -> Void
    let actions: [ToolPouchMenuAction]

    @State private var isHovering = false

    var body: some View {
        interactiveRow
    }

    @ViewBuilder
    private var interactiveRow: some View {
#if os(macOS)
        row.onHover { isHovering = $0 }
#else
        row
#endif
    }

    private var row: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            Button(action: open) {
                HStack(spacing: ToolPouchLayout.Spacing.medium) {
                    Image(systemName: "rectangle.stack")
                        .toolPouchIcon(.medium)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20)

                    Text(collection.title)
                        .font(ToolPouchLayout.Typography.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Text("\(collection.snippets?.count ?? 0)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            ToolPouchActionMenu(
                accessibilityLabel: String(format: "Actions for %@".localizedInterfaceText, collection.title),
                actions: actions
            )
            .opacity(showsActions ? 1 : 0)
            .allowsHitTesting(showsActions)
        }
        .padding(.leading, 4)
        .padding(.trailing, 6)
        .frame(minHeight: 34)
        .background(
            theme.colors.interactiveSurface.color.opacity(isHovering ? 0.72 : 0),
            in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
        )
    }

    private var showsActions: Bool {
#if os(macOS)
        isHovering
#else
        true
#endif
    }
}

private struct QuickCopyTreeAddRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title.localizedInterfaceText, systemImage: "plus.circle")
                .font(ToolPouchLayout.Typography.supporting.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
        .accessibilityLabel(title.localizedInterfaceText)
    }
}

private struct QuickCopySnippetRow: View {
    let snippet: QuickCopySnippetRecord
    let toggleFavorite: () -> Void
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
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
                .help((snippet.isFavorite ? "Remove from Favorites" : "Add to Favorites").localizedInterfaceText)
                .accessibilityLabel((snippet.isFavorite ? "Remove from Favorites" : "Add to Favorites").localizedInterfaceText)

                ToolPouchActionMenu(
                    accessibilityLabel: String(format: "Actions for %@".localizedInterfaceText, snippet.title),
                    actions: [
                        ToolPouchMenuAction("Edit", systemImage: "pencil", action: edit),
                        ToolPouchMenuAction(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive,
                            action: delete
                        )
                    ]
                )
            }

            // Center the complete text block rather than its first baseline.
            // One-line snippets then sit optically in the middle, while multiline
            // snippets retain identical padding above and below.
            HStack(alignment: .center, spacing: 8) {
                Text(snippet.content)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(4)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #if !os(watchOS)
                    .textSelection(.enabled)
                    #endif

                #if !os(watchOS)
                CopyButton(value: snippet.content)
                #endif
            }
            .padding(.horizontal, ToolPouchLayout.Spacing.medium)
            .padding(.vertical, ToolPouchLayout.Spacing.small)
            .toolPouchSurface(cornerRadius: ToolPouchLayout.Radius.control)

            #if os(watchOS)
            Text("Open this note on iPhone or Mac to copy it.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            #endif
        }
        .padding(.horizontal, ToolPouchLayout.Spacing.xLarge)
        .padding(.vertical, ToolPouchLayout.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            Label(title.localizedInterfaceText, systemImage: systemImage)
        } description: {
            Text(description.localizedInterfaceText)
        } actions: {
            Button(action: action) {
                Label(buttonTitle.localizedInterfaceText, systemImage: "plus")
            }
                .toolPouchPrimaryAction()
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
        .reportToolContentHeight(additionalHeight: 102)
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
