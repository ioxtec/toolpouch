import SwiftData
import SwiftUI

struct QuickCopyEditorRequest: Identifiable {
    enum Content {
        case folder(QuickCopyFolderRecord?)
        case collection(
            folder: QuickCopyFolderRecord,
            collection: QuickCopyCollectionRecord?
        )
        case snippet(
            collection: QuickCopyCollectionRecord,
            snippet: QuickCopySnippetRecord?
        )
    }

    let id = UUID()
    let content: Content
}

struct QuickCopyFolderEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let folder: QuickCopyFolderRecord?
    private let nextSortOrder: Int

    @State private var title: String
    @State private var details: String
    @State private var errorMessage: String?

    init(folder: QuickCopyFolderRecord?, nextSortOrder: Int) {
        self.folder = folder
        self.nextSortOrder = nextSortOrder
        _title = State(initialValue: folder?.title ?? "")
        _details = State(initialValue: folder?.details ?? "")
    }

    var body: some View {
        QuickCopyEditorForm(
            title: folder == nil ? "New Folder" : "Edit Folder",
            saveDisabled: cleanedTitle.isEmpty,
            errorMessage: errorMessage,
            preferredSize: CGSize(width: 390, height: 285),
            save: save
        ) {
            VStack(alignment: .leading, spacing: 14) {
                QuickCopyLabeledTextField(
                    label: "Name",
                    placeholder: "For example: Work",
                    text: $title,
                    lineLimit: 1...1
                )
                QuickCopyLabeledTextField(
                    label: "Description",
                    placeholder: "Optional",
                    text: $details,
                    lineLimit: 2...3
                )
            }
        }
    }

    private var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let now = Date()
        if let folder {
            folder.title = cleanedTitle
            folder.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            folder.updatedAt = now
        } else {
            modelContext.insert(
                QuickCopyFolderRecord(
                    title: cleanedTitle,
                    details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdAt: now,
                    updatedAt: now,
                    sortOrder: nextSortOrder
                )
            )
        }
        persist()
    }

    private func persist() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "The folder could not be saved."
        }
    }
}

struct QuickCopyCollectionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let folder: QuickCopyFolderRecord
    private let collection: QuickCopyCollectionRecord?
    private let nextSortOrder: Int

    @State private var title: String
    @State private var details: String
    @State private var errorMessage: String?

    init(
        folder: QuickCopyFolderRecord,
        collection: QuickCopyCollectionRecord?,
        nextSortOrder: Int
    ) {
        self.folder = folder
        self.collection = collection
        self.nextSortOrder = nextSortOrder
        _title = State(initialValue: collection?.title ?? "")
        _details = State(initialValue: collection?.details ?? "")
    }

    var body: some View {
        QuickCopyEditorForm(
            title: collection == nil ? "New Collection" : "Edit Collection",
            saveDisabled: cleanedTitle.isEmpty,
            errorMessage: errorMessage,
            preferredSize: CGSize(width: 410, height: 350),
            save: save
        ) {
            VStack(alignment: .leading, spacing: 14) {
                QuickCopyLabeledTextField(
                    label: "Name",
                    placeholder: "For example: Homebrew Commands",
                    text: $title,
                    lineLimit: 1...1
                )
                QuickCopyLabeledTextField(
                    label: "Description",
                    placeholder: "Optional",
                    text: $details,
                    lineLimit: 2...3
                )
                QuickCopyContextRow(label: "Folder", value: folder.title)
            }
        }
    }

    private var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let now = Date()
        if let collection {
            collection.title = cleanedTitle
            collection.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            collection.updatedAt = now
        } else {
            modelContext.insert(
                QuickCopyCollectionRecord(
                    title: cleanedTitle,
                    details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                    folder: folder,
                    createdAt: now,
                    updatedAt: now,
                    sortOrder: nextSortOrder
                )
            )
            folder.updatedAt = now
        }
        persist()
    }

    private func persist() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "The collection could not be saved."
        }
    }
}

struct QuickCopySnippetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let collection: QuickCopyCollectionRecord
    private let snippet: QuickCopySnippetRecord?
    private let nextSortOrder: Int

    @State private var title: String
    @State private var details: String
    @State private var content: String
    @State private var isFavorite: Bool
    @State private var errorMessage: String?

    init(
        collection: QuickCopyCollectionRecord,
        snippet: QuickCopySnippetRecord?,
        nextSortOrder: Int
    ) {
        self.collection = collection
        self.snippet = snippet
        self.nextSortOrder = nextSortOrder
        _title = State(initialValue: snippet?.title ?? "")
        _details = State(initialValue: snippet?.details ?? "")
        _content = State(initialValue: snippet?.content ?? "")
        _isFavorite = State(initialValue: snippet?.isFavorite ?? false)
    }

    var body: some View {
        QuickCopyEditorForm(
            title: snippet == nil ? "New Note" : "Edit Note",
            saveDisabled: cleanedTitle.isEmpty || cleanedContent.isEmpty,
            errorMessage: errorMessage,
            preferredSize: CGSize(width: 520, height: 540),
            save: save
        ) {
            VStack(alignment: .leading, spacing: 14) {
                QuickCopyLabeledTextField(
                    label: "Title",
                    placeholder: "What is this note for?",
                    text: $title,
                    lineLimit: 1...1
                )
                QuickCopyLabeledTextField(
                    label: "Description",
                    placeholder: "Optional",
                    text: $details,
                    lineLimit: 2...3
                )
                Toggle("Favorite", isOn: $isFavorite)

                Text("Content")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                #if os(watchOS)
                TextField("Content", text: $content, axis: .vertical)
                    .font(.body.monospaced())
                    .lineLimit(3...12)
                #else
                TextEditor(text: $content)
                    .font(.body.monospaced())
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .quickCopyInputSurface()
                #endif

                QuickCopyContextRow(
                    label: "Collection",
                    value: collection.title
                )
            }
        }
    }

    private var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let now = Date()
        if let snippet {
            snippet.title = cleanedTitle
            snippet.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            // Copy notes must round-trip exactly. In particular, leading
            // whitespace can be meaningful in scripts, YAML, and templates.
            snippet.content = content
            snippet.isFavorite = isFavorite
            snippet.updatedAt = now
        } else {
            modelContext.insert(
                QuickCopySnippetRecord(
                    title: cleanedTitle,
                    details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                    content: content,
                    isFavorite: isFavorite,
                    collection: collection,
                    createdAt: now,
                    updatedAt: now,
                    sortOrder: nextSortOrder
                )
            )
            collection.updatedAt = now
            collection.folder?.updatedAt = now
        }
        persist()
    }

    private func persist() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "The note could not be saved."
        }
    }
}

private struct QuickCopyEditorForm<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let title: String
    let saveDisabled: Bool
    let errorMessage: String?
    let preferredSize: CGSize
    let save: () -> Void
    private let content: Content

    init(
        title: String,
        saveDisabled: Bool,
        errorMessage: String?,
        preferredSize: CGSize,
        save: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.saveDisabled = saveDisabled
        self.errorMessage = errorMessage
        self.preferredSize = preferredSize
        self.save = save
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .toolPouchIcon(.small, weight: .semibold)
                }
                .buttonStyle(.borderless)
                .help("Cancel")
                .accessibilityLabel("Cancel")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                content
                    .padding(18)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.glass)
                Button("Save", action: save)
                    .buttonStyle(.glassProminent)
                    .disabled(saveDisabled)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .foregroundStyle(theme.colors.primaryText.color)
        .tint(theme.colors.primaryAccent.color)
        .background(theme.colors.elevatedSurface.color)
        #if os(macOS)
        .frame(
            width: preferredSize.width,
            height: preferredSize.height
        )
        #endif
    }
}

private struct QuickCopyLabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let lineLimit: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(lineLimit)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .quickCopyInputSurface()
        }
    }
}

private struct QuickCopyContextRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .quickCopyInputSurface()
    }
}

private extension View {
    func quickCopyInputSurface() -> some View {
        modifier(QuickCopyInputSurfaceModifier())
    }
}

private struct QuickCopyInputSurfaceModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                theme.colors.interactiveSurface.color,
                in: RoundedRectangle(cornerRadius: 9)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(theme.colors.border.color.opacity(0.8), lineWidth: 1)
            }
    }
}
