import SwiftUI
import UniformTypeIdentifiers

struct HashChecksumView: View {
    private enum InputMode: String, CaseIterable, Identifiable {
        case text
        case file

        var id: Self { self }

        var title: String {
            switch self {
            case .text: "Text"
            case .file: "File"
            }
        }
    }

    private let calculator: any HashCalculating

    @State private var inputMode: InputMode = .text
    @State private var algorithm: HashAlgorithm = .sha256
    @State private var textInput = ""
    @State private var selectedFileURL: URL?
    @State private var digest: HashDigest?
    @State private var expectedChecksum = ""
    @State private var errorMessage: String?
    @State private var isSelectingFile = false
    @State private var isCalculating = false

    init(calculator: any HashCalculating) {
        self.calculator = calculator
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                ScreenHeader(
                    title: "Hash & Checksum",
                    subtitle: "Calculate and compare hashes locally for text or files."
                )
                hashPanel
            }
        }
        .scrollIndicators(.never)
        .task(id: request) {
            await calculateHash()
        }
        #if !os(macOS)
        .fileImporter(
            isPresented: $isSelectingFile,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false,
            onCompletion: handleFileSelection
        )
        #endif
    }

    private var hashPanel: some View {
        ToolSectionCard {
            controls
            Divider()
            inputSection
            Divider()
            resultSection
            comparisonSection
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            #if os(watchOS)
            Picker("Input", selection: $inputMode) {
                ForEach(InputMode.allCases) { mode in
                    Text(mode.title.localizedInterfaceText).tag(mode)
                }
            }
            #else
            ToolPouchSegmentedControl(
                InputMode.allCases,
                selection: $inputMode,
                title: \.title
            )
            #endif

            Picker("Algorithm", selection: $algorithm) {
                ForEach(HashAlgorithm.allCases) { algorithm in
                    Text(algorithm.title.localizedInterfaceText).tag(algorithm)
                }
            }

            if algorithm.isLegacy {
                Label(
                    "MD5 is provided only for compatibility and file checksums.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        if inputMode == .text {
            textInputSection
        } else {
            fileInputSection
        }
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Text")
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                if !textInput.isEmpty {
                    Button("Clear") { textInput = "" }
                        .buttonStyle(.borderless)
                }
            }

            TextEditor(text: $textInput)
                .font(.system(.body, design: .monospaced))
                .toolPouchEditorSurface(minimumHeight: 104)
                .accessibilityLabel("Text to hash")
        }
    }

    private var fileInputSection: some View {
        Button {
            #if os(macOS)
            if let url = CenteredFilePanel.chooseFile(
                title: "Choose a File",
                message: "Select a file to calculate its checksum."
            ) {
                selectedFileURL = url
            }
            #else
            isSelectingFile = true
            #endif
        } label: {
            VStack(spacing: 10) {
                Image(systemName: selectedFileURL == nil ? "doc.badge.plus" : "doc")
                    .toolPouchIcon(.large, weight: .medium)

                Text(selectedFileURL?.lastPathComponent ?? "Choose or drop a file".localizedInterfaceText)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("The file stays on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(ToolPouchLayout.Spacing.xLarge)
            .contentShape(.rect)
            .toolPouchSurface(interactive: true, cornerRadius: ToolPouchLayout.Radius.control)
        }
        .buttonStyle(.plain)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, !url.hasDirectoryPath else { return false }
            selectedFileURL = url
            return true
        }
        .accessibilityLabel("Choose a file to hash")
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(algorithm.title.localizedInterfaceText)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                if let digest {
                    CopyButton(value: digest.value)
                }
            }

            Group {
                if isCalculating {
                    ProgressView("Calculating checksum…")
                } else if let errorMessage {
                    Label(errorMessage, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else if let digest {
                    Text(digest.value)
                        .foregroundStyle(.primary)
                } else {
                    Text("The checksum appears here.")
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
            .padding(ToolPouchLayout.Spacing.xLarge)
            .toolPouchSurface(interactive: true, cornerRadius: ToolPouchLayout.Radius.control)
        }
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compare")
                .font(ToolPouchLayout.Typography.sectionTitle)

            TextField("Paste an expected checksum", text: $expectedChecksum)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .toolPouchControlSurface()

            if !expectedChecksum.isEmpty, let digest {
                if digest.matches(expectedChecksum) {
                    Label("Checksums match", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Checksums do not match", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var request: HashRequest {
        switch inputMode {
        case .text:
            textInput.isEmpty ? .empty : .text(textInput, algorithm)
        case .file:
            selectedFileURL.map { .file($0, algorithm) } ?? .empty
        }
    }

    @MainActor
    private func calculateHash() async {
        digest = nil
        errorMessage = nil

        switch request {
        case .empty:
            isCalculating = false
        case let .text(value, algorithm):
            isCalculating = false
            digest = calculator.hash(Data(value.utf8), using: algorithm)
        case let .file(url, algorithm):
            isCalculating = true
            defer { isCalculating = false }

            do {
                digest = try await calculator.hash(fileAt: url, using: algorithm)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        do {
            selectedFileURL = try result.get().first
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum HashRequest: Hashable {
    case empty
    case text(String, HashAlgorithm)
    case file(URL, HashAlgorithm)
}
