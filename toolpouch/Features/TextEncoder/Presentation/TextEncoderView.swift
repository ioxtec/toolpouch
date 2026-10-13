import SwiftUI

struct TextEncoderView: View {
    private let converter: any TextEncodingConverting

    @State private var encoding: BinaryTextEncoding = .base64
    @State private var direction: TextConversionDirection = .encode
    @State private var input = ""
    @State private var output = ""
    @State private var errorMessage: String?

    init(converter: any TextEncodingConverting) {
        self.converter = converter
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header
                converterPanel
            }
        }
        .scrollIndicators(.never)
        .task { convert() }
        .onChange(of: request) { convert() }
    }

    private var header: some View {
        ScreenHeader(
            title: "Text Encoder",
            subtitle: "Convert UTF-8 text using common binary-to-text formats.",
            density: isWatch ? .compact : .regular
        )
    }

    private var converterPanel: some View {
        ToolSectionCard {
            controls
            Divider()
            inputSection
            swapButton
            outputSection
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Format", selection: $encoding) {
                ForEach(BinaryTextEncoding.allCases) { encoding in
                    Text(encoding.title.localizedInterfaceText).tag(encoding)
                }
            }

            #if os(watchOS)
            Picker("Direction", selection: directionSelection) {
                ForEach(TextConversionDirection.allCases) { direction in
                    Text(direction.title.localizedInterfaceText).tag(direction)
                }
            }
            #else
            ToolPouchSegmentedControl(
                TextConversionDirection.allCases,
                selection: directionSelection,
                title: \.title
            )
            #endif

            Text(encoding.description.localizedInterfaceText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(direction.inputTitle)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                if !input.isEmpty {
                    Button("Clear") { input = "" }
                        .buttonStyle(.borderless)
                }
            }

            #if os(watchOS)
            TextField(direction.inputTitle, text: $input, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .lineLimit(3...8)
                .toolPouchControlSurface()
                .accessibilityLabel(direction.inputTitle)
            #else
            TextEditor(text: $input)
                .font(.system(.body, design: .monospaced))
                .toolPouchEditorSurface(minimumHeight: 92)
                .accessibilityLabel(direction.inputTitle)
            #endif
        }
    }

    private var swapButton: some View {
        Button {
            changeDirection(to: direction.opposite)
        } label: {
            Label("Reverse Direction", systemImage: "arrow.up.arrow.down")
        }
        .buttonStyle(.borderless)
        .frame(maxWidth: .infinity)
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(direction.outputTitle)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                #if !os(watchOS)
                if errorMessage == nil, !output.isEmpty {
                    CopyButton(value: output)
                }
                #endif
            }

            ScrollView([.horizontal, .vertical]) {
                Group {
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    } else if output.isEmpty {
                        Text("The result appears here.")
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            #if !os(watchOS)
                            .textSelection(.enabled)
                            #endif
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .toolPouchEditorSurface(minimumHeight: 72)
        }
    }

    private var isWatch: Bool {
        #if os(watchOS)
        true
        #else
        false
        #endif
    }

    private var request: ConversionRequest {
        ConversionRequest(
            input: input,
            encoding: encoding,
            direction: direction
        )
    }

    private var directionSelection: Binding<TextConversionDirection> {
        Binding(
            get: { direction },
            set: { changeDirection(to: $0) }
        )
    }

    private func changeDirection(to newDirection: TextConversionDirection) {
        guard newDirection != direction else { return }

        if errorMessage == nil, !output.isEmpty {
            input = output
        }
        direction = newDirection
    }

    private func convert() {
        guard !input.isEmpty else {
            output = ""
            errorMessage = nil
            return
        }

        do {
            output = try converter.convert(
                input,
                using: encoding,
                direction: direction
            )
            errorMessage = nil
        } catch {
            output = ""
            errorMessage = error.localizedDescription
        }
    }
}

private struct ConversionRequest: Equatable {
    let input: String
    let encoding: BinaryTextEncoding
    let direction: TextConversionDirection
}
