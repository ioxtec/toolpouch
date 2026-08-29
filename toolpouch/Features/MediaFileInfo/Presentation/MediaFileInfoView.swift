import SwiftUI
import UniformTypeIdentifiers

struct MediaFileInfoView: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var model: MediaFileInfoModel

    init(inspector: any MediaFileInspecting) {
        _model = StateObject(wrappedValue: MediaFileInfoModel(inspector: inspector))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Media File Info",
                    subtitle: "Inspect image, audio, and video files without uploading them."
                )
                contentPanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
    }

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            filePicker

            if model.selectedFileURL != nil || model.errorMessage != nil {
                Divider()
                resultContent
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var filePicker: some View {
        Button(action: chooseFile) {
            VStack(spacing: 10) {
                Image(systemName: model.isDropTargeted ? "arrow.down.circle.fill" : "play.rectangle.on.rectangle")
                    .toolPouchIcon(.large, weight: .medium)
                    .foregroundStyle(model.isDropTargeted ? theme.colors.primaryAccent.color : theme.colors.primaryText.color)
                    .contentTransition(.symbolEffect(.replace))

                Text(dropZoneTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("or click to choose from Finder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Images, audio, and video")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 140)
            .contentShape(.rect)
            .background(
                model.isDropTargeted ? theme.colors.primaryAccent.color.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        model.isDropTargeted ? theme.colors.primaryAccent.color : Color.secondary.opacity(0.45),
                        style: StrokeStyle(lineWidth: model.isDropTargeted ? 2 : 1, dash: [7, 5])
                    )
            }
        }
        .buttonStyle(.plain)
        .dropDestination(
            for: URL.self,
            action: handleDrop,
            isTargeted: { model.isDropTargeted = $0 }
        )
        .accessibilityLabel("Choose a media file to inspect")
    }

    @ViewBuilder
    private var resultContent: some View {
        if model.isInspecting {
            ProgressView("Reading media information…")
                .frame(maxWidth: .infinity, minHeight: 140)
        } else if let errorMessage = model.errorMessage {
            VStack(spacing: 10) {
                Label(errorMessage, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                if let details = model.errorDetails {
                    HStack(spacing: 8) {
                        Text(details)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        CopyButton(value: details)
                    }
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
                Button("Choose Another File", action: chooseFile)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else if let inspection = model.inspection {
            inspectionDetails(inspection)
        }
    }

    private func inspectionDetails(_ inspection: MediaFileInspection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: inspection.kind.systemImage)
                    .toolPouchIcon(.medium, weight: .semibold)
                    .foregroundStyle(theme.colors.primaryAccent.color)
                    .frame(width: 34, height: 34)
                    .toolPouchCircleSurface()

                VStack(alignment: .leading, spacing: 2) {
                    Text(inspection.filename)
                        .font(.headline)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    Text(inspection.kind.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Button("Clear", action: model.clear)
                    .buttonStyle(.borderless)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                detail("Type", inspection.typeName, icon: "doc")
                detail("File size", inspection.formattedFileSize, icon: "internaldrive")
                optionalDetail("Duration", inspection.formattedDuration, icon: "timer")
                optionalDetail("Dimensions", inspection.dimensions, icon: "rectangle.expand.vertical")
                optionalDetail("Created", inspection.formattedCreationDate, icon: "calendar")
            }

            if !inspection.waveformSamples.isEmpty {
                waveformSection(inspection.waveformSamples)
            }

            if !inspection.tracks.isEmpty {
                tracksSection(inspection.tracks)
            }

            Label("The file is inspected locally and is not uploaded.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func waveformSection(_ samples: [Float]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Waveform", systemImage: "waveform")
                .font(.headline)

            MediaWaveformView(samples: samples)
                .frame(height: 112)
                .padding(.horizontal, 10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func tracksSection(_ tracks: [MediaTrackInspection]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tracks")
                .font(.headline)

            ForEach(tracks) { track in
                VStack(alignment: .leading, spacing: 10) {
                    Label("\(track.kind.title) · \(track.codec)", systemImage: track.kind.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.colors.primaryAccent.color)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        optionalTrackValue("Resolution", track.dimensions)
                        optionalTrackValue("Frame rate", track.frameRate)
                        optionalTrackValue("Bitrate", track.bitrate)
                        optionalTrackValue("Sample rate", track.sampleRate)
                        optionalTrackValue("Channels", track.channelCount)
                        optionalTrackValue("Language", track.language)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    @ViewBuilder
    private func optionalDetail(_ title: String, _ value: String?, icon: String) -> some View {
        if let value {
            detail(title, value, icon: icon)
        }
    }

    private func detail(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .textSelection(.enabled)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func optionalTrackValue(_ label: String, _ value: String?) -> some View {
        if let value {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.medium))
                    .textSelection(.enabled)
            }
        }
    }

    private var dropZoneTitle: String {
        if model.isDropTargeted {
            "Drop the media file here"
        } else if let selectedFileURL = model.selectedFileURL {
            selectedFileURL.lastPathComponent
        } else {
            "Drag a media file here"
        }
    }

    private func chooseFile() {
        guard let url = CenteredFilePanel.chooseFile(
            title: "Choose a Media File",
            message: "Select an image, audio file, or video file to inspect locally.",
            allowedContentTypes: [.image, .audio, .movie]
        ) else { return }
        Task { await model.select(url) }
    }

    private func handleDrop(_ urls: [URL], location: CGPoint) -> Bool {
        guard let url = urls.first, isSupportedMedia(url) else { return false }
        Task { await model.select(url) }
        return true
    }

    private func isSupportedMedia(_ url: URL) -> Bool {
        guard !url.hasDirectoryPath else { return false }
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
        return MediaFileKind(
            contentType: type,
            fileExtension: url.pathExtension
        ) != nil
    }
}

private struct MediaWaveformView: View {
    @Environment(\.appTheme) private var theme
    let samples: [Float]

    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }
            let middle = size.height / 2
            let step = size.width / CGFloat(samples.count)
            var path = Path()

            for (index, sample) in samples.enumerated() {
                let x = (CGFloat(index) + 0.5) * step
                let amplitude = max(1, CGFloat(sample) * (middle - 8))
                path.move(to: CGPoint(x: x, y: middle - amplitude))
                path.addLine(to: CGPoint(x: x, y: middle + amplitude))
            }

            context.stroke(
                path,
                with: .color(theme.colors.primaryAccent.color),
                style: StrokeStyle(lineWidth: max(1, min(3, step * 0.65)), lineCap: .round)
            )
        }
        .accessibilityLabel("Audio waveform")
    }
}
