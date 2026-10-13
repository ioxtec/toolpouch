import SwiftUI

struct ArchiveToolView: View {
    @State private var model: ArchiveToolModel
    @State private var isDropTargeted = false

    init(archiveManager: any ArchiveManaging) {
        _model = State(initialValue: ArchiveToolModel(archiveManager: archiveManager))
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header
                archivePanel
            }
        }
        .scrollIndicators(.never)
    }

    private var header: some View {
        ScreenHeader(
            title: "Archive Tool",
            subtitle: "Compress files and folders, or extract common archive formats.",
            density: isWatch ? .compact : .regular
        )
    }

    private var archivePanel: some View {
        ToolSectionCard {
            controls
            Divider()
            compressSection
            Divider()
            decompressSection
            statusSection
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            #if os(watchOS)
            Picker("Format", selection: $model.selectedFormat) {
                ForEach(ArchiveFormat.supportedCompressionFormats) { format in
                    Text(format.title.localizedInterfaceText).tag(format)
                }
            }
            #else
            ToolPouchSegmentedControl(
                ArchiveFormat.supportedCompressionFormats,
                selection: $model.selectedFormat,
                title: \.title
            )
            #endif

            Text(model.selectedFormat.description.localizedInterfaceText)
                .font(ToolPouchLayout.Typography.supporting)
                .foregroundStyle(.secondary)
        }
    }

    private var compressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compress")
                .font(ToolPouchLayout.Typography.sectionTitle)

            Text("Choose or drop a file or folder, then choose where to save the archive.")
                .font(.caption)
                .foregroundStyle(.secondary)

            dropTarget(
                icon: "folder.badge.gearshape",
                hint: "Drop a folder to compress"
            ) { urls in
                guard let url = urls.first else { return }
                model.compress(folderURL: url)
            }
            #if os(macOS)
            Button("Choose File or Folder…") { model.chooseSource(compress: true) }
                .disabled(model.isWorking)
            #endif
        }
    }

    private var decompressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Decompress")
                .font(ToolPouchLayout.Typography.sectionTitle)

            Text("Choose or drop a ZIP, GZIP, BZIP2, XZ, TAR, or TGZ archive, then choose its destination.")
                .font(.caption)
                .foregroundStyle(.secondary)

            dropTarget(
                icon: "shippingbox.and.arrow.backward",
                hint: "Drop an archive to extract"
            ) { urls in
                guard let url = urls.first else { return }
                model.decompress(archiveURL: url)
            }
            #if os(macOS)
            Button("Choose Archive…") { model.chooseSource(compress: false) }
                .disabled(model.isWorking)
            #endif
        }
    }

    private func dropTarget(
        icon: String,
        hint: String,
        onDrop: @escaping ([URL]) -> Void
    ) -> some View {
        let surface = RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
            .fill(.clear)
            .frame(maxWidth: .infinity, minHeight: 96)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(hint.localizedInterfaceText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
                    .strokeBorder(
                        isDropTargeted ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control))
            .toolPouchSurface(interactive: true, cornerRadius: ToolPouchLayout.Radius.control)

        #if os(watchOS)
        return surface
            .accessibilityLabel(hint.localizedInterfaceText)
        #else
        return surface
            .dropDestination(for: URL.self) { urls, _ in
                onDrop(urls)
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
            .accessibilityLabel(hint.localizedInterfaceText)
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

    private var isWatch: Bool {
        #if os(watchOS)
        true
        #else
        false
        #endif
    }
}
