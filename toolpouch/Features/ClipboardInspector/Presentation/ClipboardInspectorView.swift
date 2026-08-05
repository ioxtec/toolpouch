#if os(macOS)
import AppKit
import SwiftUI

struct ClipboardInspectorView: View {
    @State private var model: ClipboardInspectorModel
    @State private var isConfirmingClear = false

    init(inspector: any ClipboardInspecting) {
        _model = State(
            initialValue: ClipboardInspectorModel(inspector: inspector)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Clipboard Inspector",
                    subtitle: "Preview the current clipboard content and its available formats."
                )
                actions
                content
                privacyNotice
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .task { await model.monitor() }
        .alert("Clear Clipboard?", isPresented: $isConfirmingClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { model.clear() }
        } message: {
            Text("This removes the current clipboard content. This action cannot be undone.")
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Label(itemCountTitle, systemImage: "clipboard")
                .font(.subheadline.weight(.medium))

            Text(model.snapshot.capturedAt, style: .time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                model.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.glass)

            Button(role: .destructive) {
                isConfirmingClear = true
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.glass)
            .disabled(model.snapshot.isEmpty)
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var content: some View {
        if model.snapshot.isEmpty {
            ContentUnavailableView {
                Label("Clipboard Is Empty", systemImage: "clipboard")
            } description: {
                Text("Copy text, an image, or a file to inspect it here.")
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(model.snapshot.items) { item in
                    ClipboardItemCard(item: item)
                }
            }
        }
    }

    private var privacyNotice: some View {
        Label(
            "Clipboard content stays on this Mac and is not saved by ToolPouch.",
            systemImage: "hand.raised"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var itemCountTitle: String {
        let count = model.snapshot.items.count
        return count == 1 ? "1 Item" : "\(count) Items"
    }
}

private struct ClipboardItemCard: View {
    let item: ClipboardItemSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            preview

            if !item.representations.isEmpty {
                Divider()
                representations
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: item.kind.systemImage)
                .toolPouchIcon(.medium)
                .frame(width: 24)

            Text(item.kind.title)
                .font(.headline)

            Spacer()

            if item.estimatedByteCount > 0 {
                Text(
                    ByteCountFormatter.string(
                        fromByteCount: Int64(item.estimatedByteCount),
                        countStyle: .file
                    )
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.kind {
        case .text:
            textPreview
        case .image:
            imagePreview
        case .file:
            filePreview
        case .other:
            Label(
                "This clipboard format does not have a visual preview yet.",
                systemImage: "questionmark.square.dashed"
            )
            .foregroundStyle(.secondary)
        }
    }

    private var textPreview: some View {
        HStack(alignment: .top, spacing: 10) {
            ScrollView {
                Text(item.text ?? "")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 60, maxHeight: 220)

            if let text = item.text, !text.isEmpty {
                CopyButton(value: text)
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let data = item.imageData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 260)
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        } else {
            Label("The image preview is unavailable.", systemImage: "photo.badge.exclamationmark")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var filePreview: some View {
        if let fileURL = item.fileURL {
            HStack(spacing: 12) {
                Image(systemName: "doc")
                    .toolPouchIcon(.large)

                VStack(alignment: .leading, spacing: 3) {
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                    Text(fileURL.deletingLastPathComponent().path(percentEncoded: false))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }
            .textSelection(.enabled)
        }
    }

    private var representations: some View {
        DisclosureGroup("Formats (\(item.representations.count))") {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(item.representations) { representation in
                    HStack(alignment: .firstTextBaseline) {
                        Text(representation.typeIdentifier)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                        Spacer()
                        Text(
                            ByteCountFormatter.string(
                                fromByteCount: Int64(representation.byteCount),
                                countStyle: .file
                            )
                        )
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
        .font(.subheadline)
    }
}
#endif
