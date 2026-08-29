import SwiftUI

struct ArchiveToolView: View {
    @State private var model: ArchiveToolModel
    @State private var isDropTargeted = false

    init(archiveManager: any ArchiveManaging) {
        _model = State(initialValue: ArchiveToolModel(archiveManager: archiveManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                header
                archivePanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Archive Tool")
                .font(.headline)
            #if !os(watchOS)
            Text("Compress files and folders, or extract ZIP, GZIP, BZIP2, XZ, TAR, and TGZ archives.")
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
        }
    }

    private var archivePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            controls
            Divider()
            compressSection
            Divider()
            decompressSection
            statusSection
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Format", selection: $model.selectedFormat) {
                ForEach(ArchiveFormat.supportedCompressionFormats) { format in
                    Text(format.title).tag(format)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.segmented)
            .labelsHidden()
            #endif

            Text(model.selectedFormat.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var compressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compress")
                .font(.headline)

            Text("Drag a folder or file here to create a \(model.selectedFormat.title) archive next to it.")
                .font(.caption)
                .foregroundStyle(.secondary)

            dropTarget(
                icon: "folder.badge.gearshape",
                hint: "Drop a folder to compress"
            ) { urls in
                guard let url = urls.first else { return }
                model.compress(folderURL: url)
            }
        }
    }

    private var decompressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Decompress")
                .font(.headline)

            Text("Drop a .zip, .gz, .bz2, .xz, .tar, or .tgz archive to extract it next to the original.")
                .font(.caption)
                .foregroundStyle(.secondary)

            dropTarget(
                icon: "shippingbox.and.arrow.backward",
                hint: "Drop an archive to extract"
            ) { urls in
                guard let url = urls.first else { return }
                model.decompress(archiveURL: url)
            }
        }
    }

    private func dropTarget(
        icon: String,
        hint: String,
        onDrop: @escaping ([URL]) -> Void
    ) -> some View {
        let surface = RoundedRectangle(cornerRadius: 10)
            .fill(.quaternary.opacity(isDropTargeted ? 0.9 : 0.6))
            .frame(maxWidth: .infinity, minHeight: 96)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isDropTargeted ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))

        #if os(watchOS)
        return surface
            .accessibilityLabel(hint)
        #else
        return surface
            .dropDestination(for: URL.self) { urls, _ in
                onDrop(urls)
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
            .accessibilityLabel(hint)
        #endif
    }

    @ViewBuilder
    private var statusSection: some View {
        if !model.isWorking {
            switch model.state {
            case .idle:
                EmptyView()
            case let .succeeded(message):
                Label(message, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            case let .failed(message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            case .working:
                ProgressView()
            }
        } else {
            HStack(spacing: 8) {
                ProgressView()
                Text("Working…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
