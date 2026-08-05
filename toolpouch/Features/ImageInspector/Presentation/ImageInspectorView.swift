import SwiftUI
import UniformTypeIdentifiers

struct ImageInspectorView: View {
    @Environment(\.openURL) private var openURL
    @State private var model: ImageInspectorModel
    @State private var isSelectingFile = false
    @State private var isDropTargeted = false
    @State private var shouldResize = false
    @State private var maximumWidth = "1920"
    @State private var maximumHeight = "1080"
    @State private var outputFormat = ImageOutputFormat.jpeg
    @State private var jpegQuality = 88.0
    @FocusState private var focusedDimension: ImageDimension?

    init(inspector: any ImageInspecting) {
        _model = State(initialValue: ImageInspectorModel(inspector: inspector))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Image Toolkit",
                    subtitle: "Inspect metadata, resize, and convert images locally with Rust."
                )
                contentPanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        #if os(iOS)
        .fileImporter(
            isPresented: $isSelectingFile,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: handleFileSelection
        )
        #endif
        .onChange(of: model.inspection) { _, inspection in
            guard let inspection else { return }
            maximumWidth = String(inspection.width)
            maximumHeight = String(inspection.height)
        }
        .onChange(of: maximumWidth) { _, value in
            guard focusedDimension == .width else { return }
            updateHeight(for: value)
        }
        .onChange(of: maximumHeight) { _, value in
            guard focusedDimension == .height else { return }
            updateWidth(for: value)
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
        Button {
            chooseImage()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: isDropTargeted ? "arrow.down.circle.fill" : "photo.badge.plus")
                    .toolPouchIcon(.large, weight: .medium)
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.primary)
                    .contentTransition(.symbolEffect(.replace))

                Text(dropZoneTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("or click to choose from Finder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("PNG, JPEG, GIF, WebP, TIFF, BMP, ICO, and PNM")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 150)
            .contentShape(.rect)
            .background(
                isDropTargeted ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.45),
                        style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [7, 5])
                    )
            }
        }
        .buttonStyle(.plain)
        .dropDestination(
            for: URL.self,
            action: handleDrop,
            isTargeted: { isDropTargeted = $0 }
        )
        .accessibilityLabel("Choose an image to inspect")
    }

    @ViewBuilder
    private var resultContent: some View {
        if model.isInspecting {
            ProgressView("Inspecting image…")
                .frame(maxWidth: .infinity, minHeight: 120)
        } else if let errorMessage = model.errorMessage {
            VStack(spacing: 10) {
                Label(errorMessage, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Button("Choose Another Image") { chooseImage() }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else if let inspection = model.inspection {
            inspectionDetails(inspection)
        }
    }

    private func inspectionDetails(_ inspection: ImageInspection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Image details")
                    .font(.headline)
                Spacer()
                Button("Clear") { model.clear() }
                    .buttonStyle(.borderless)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                detail("Dimensions", inspection.dimensions, icon: "ruler")
                detail("Resolution", inspection.megapixels, icon: "square.resize")
                detail("Format", inspection.format, icon: "doc")
                detail("File size", inspection.formattedFileSize, icon: "externaldrive")
                detail("Color", inspection.colorModel, icon: "paintpalette")
                detail("Channels", "\(inspection.channelCount)", icon: "slider.horizontal.3")
                detail("Depth", inspection.bitDepth, icon: "circle.lefthalf.filled")
                detail(
                    "Transparency",
                    inspection.hasAlpha ? "Included" : "Not included",
                    icon: "checkerboard.rectangle"
                )
            }

            metadataSection

            Divider()

            transformSection

            Label("The image is inspected locally and is not uploaded.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        if let metadata = model.metadata {
            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Metadata")
                    .font(.headline)

                if metadata.hasExifValues {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 10)],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        optionalDetail("Camera maker", metadata.cameraMake, icon: "camera")
                        optionalDetail("Camera model", metadata.cameraModel, icon: "camera.fill")
                        optionalDetail("Lens", metadata.lensModel, icon: "camera.aperture")
                        optionalDetail("Taken", metadata.capturedAt, icon: "calendar")
                        optionalDetail("Exposure", metadata.exposureTime, icon: "timer")
                        optionalDetail("Aperture", metadata.aperture, icon: "camera.aperture")
                        optionalDetail("ISO", metadata.iso, icon: "sun.max")
                        optionalDetail("Focal length", metadata.focalLength, icon: "scope")
                        optionalDetail("Orientation", metadata.orientation, icon: "rotate.right")
                    }
                } else {
                    Text("This image does not contain common EXIF camera data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let coordinates = metadata.coordinateText {
                    HStack(spacing: 10) {
                        Label(coordinates, systemImage: "location.fill")
                            .font(.system(.subheadline, design: .monospaced))
                            .textSelection(.enabled)
                        Spacer()
                        CopyButton(value: coordinates)
                        if let mapURL = metadata.mapURL {
                            Button {
                                openURL(mapURL)
                            } label: {
                                Image(systemName: "map")
                                    .toolPouchIcon(.small)
                            }
                            .buttonStyle(.borderless)
                            .help("Open in Maps")
                        }
                    }
                    .padding(10)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var transformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resize & Convert")
                .font(.headline)

            Picker("Output format", selection: $outputFormat) {
                ForEach(ImageOutputFormat.allCases) { format in
                    Text(format.title).tag(format)
                }
            }

            HStack {
                Toggle("Resize image", isOn: $shouldResize)
                Spacer()
                if shouldResize, let scalePercentage {
                    Text("Size \(scalePercentage)%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
            }

            if shouldResize {
                HStack(spacing: 10) {
                    dimensionField("Width", text: $maximumWidth, dimension: .width)
                    Image(systemName: "lock.fill")
                        .toolPouchIcon(.small)
                        .foregroundStyle(.secondary)
                        .help("Aspect ratio is preserved")
                    dimensionField("Height", text: $maximumHeight, dimension: .height)
                }

                Text("Changing either dimension updates the other and preserves the original proportions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if outputFormat == .jpeg {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("JPEG quality")
                        Spacer()
                        Text("\(Int(jpegQuality))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $jpegQuality, in: 40...100, step: 1)
                }
            }

            HStack {
                Button {
                    beginTransform()
                } label: {
                    if model.isTransforming {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Save Converted Image", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isTransforming || transformOptions == nil)

                #if os(iOS)
                if let transformedFileURL = model.transformedFileURL {
                    ShareLink(item: transformedFileURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                #endif
            }

            if let message = model.transformMessage {
                Label(
                    message,
                    systemImage: model.transformedFileURL == nil ? "xmark.circle.fill" : "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(model.transformedFileURL == nil ? .red : .green)
            }
        }
    }

    @ViewBuilder
    private func optionalDetail(_ title: String, _ value: String?, icon: String) -> some View {
        if let value {
            detail(title, value, icon: icon)
        }
    }

    private func dimensionField(
        _ title: String,
        text: Binding<String>,
        dimension: ImageDimension
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Pixels", text: text)
                .textFieldStyle(.roundedBorder)
                .focused($focusedDimension, equals: dimension)
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
        }
    }

    private var transformOptions: ImageTransformOptions? {
        var width: UInt32 = 0
        var height: UInt32 = 0
        if shouldResize {
            guard let parsedWidth = UInt32(maximumWidth),
                  let parsedHeight = UInt32(maximumHeight),
                  (1...20_000).contains(parsedWidth),
                  (1...20_000).contains(parsedHeight) else {
                return nil
            }
            width = parsedWidth
            height = parsedHeight
        }
        return ImageTransformOptions(
            maximumWidth: width,
            maximumHeight: height,
            format: outputFormat,
            quality: UInt8(jpegQuality)
        )
    }

    private func beginTransform() {
        guard let sourceURL = model.selectedFileURL,
              let options = transformOptions else { return }

        #if os(macOS)
        guard let outputURL = MacOSImageFilePicker.chooseOutputURL(
            sourceURL: sourceURL,
            format: outputFormat
        ) else { return }
        #else
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent)
            .appendingPathExtension(outputFormat.fileExtension)
        #endif

        Task { await model.transform(to: outputURL, options: options) }
    }

    private var scalePercentage: Int? {
        guard let inspection = model.inspection,
              inspection.width > 0,
              let width = Double(maximumWidth) else { return nil }
        return Int((width / Double(inspection.width) * 100).rounded())
    }

    private func updateHeight(for widthText: String) {
        guard let inspection = model.inspection,
              inspection.width > 0,
              let width = Double(widthText),
              width > 0 else { return }
        let height = width * Double(inspection.height) / Double(inspection.width)
        maximumHeight = String(max(1, Int(height.rounded())))
    }

    private func updateWidth(for heightText: String) {
        guard let inspection = model.inspection,
              inspection.height > 0,
              let height = Double(heightText),
              height > 0 else { return }
        let width = height * Double(inspection.width) / Double(inspection.height)
        maximumWidth = String(max(1, Int(width.rounded())))
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

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            Task { await model.select(url) }
        } catch {
            if (error as? CocoaError)?.code != .userCancelled {
                model.showSelectionError(error)
            }
        }
    }

    private var dropZoneTitle: String {
        if isDropTargeted {
            "Drop the image here"
        } else if let selectedFileURL = model.selectedFileURL {
            selectedFileURL.lastPathComponent
        } else {
            "Drag an image here"
        }
    }

    private func chooseImage() {
        #if os(macOS)
        guard let url = MacOSImageFilePicker.chooseImage() else { return }
        Task { await model.select(url) }
        #else
        isSelectingFile = true
        #endif
    }

    private func handleDrop(_ urls: [URL], location: CGPoint) -> Bool {
        guard let url = urls.first, isSupportedImage(url) else { return false }
        Task { await model.select(url) }
        return true
    }

    private func isSupportedImage(_ url: URL) -> Bool {
        guard !url.hasDirectoryPath else { return false }
        let values = try? url.resourceValues(forKeys: [.contentTypeKey])
        return values?.contentType?.conforms(to: .image) == true
    }
}

private enum ImageDimension: Hashable {
    case width
    case height
}
