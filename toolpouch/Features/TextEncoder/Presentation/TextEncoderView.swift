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
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                header
                converterPanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .task { convert() }
        .onChange(of: request) { convert() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Text Encoder")
                .font(.title2.bold())
            #if !os(watchOS)
            Text("Convert UTF-8 text using common binary-to-text formats.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #endif
        }
    }

    private var converterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            controls
            Divider()
            inputSection
            swapButton
            outputSection
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Format", selection: $encoding) {
                ForEach(BinaryTextEncoding.allCases) { encoding in
                    Text(encoding.title).tag(encoding)
                }
            }

            Picker("Direction", selection: directionSelection) {
                ForEach(TextConversionDirection.allCases) { direction in
                    Text(direction.title).tag(direction)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.segmented)
            .labelsHidden()
            #endif

            Text(encoding.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(direction.inputTitle)
                    .font(.headline)
                Spacer()
                if !input.isEmpty {
                    Button("Clear") { input = "" }
                        .buttonStyle(.borderless)
                }
            }

            #if os(watchOS)
            TextField(direction.inputTitle, text: $input, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .lineLimit(3...8)
                .background(
                    .quaternary,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .accessibilityLabel(direction.inputTitle)
            #else
            TextEditor(text: $input)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 96)
                .background(
                    .quaternary,
                    in: RoundedRectangle(cornerRadius: 10)
                )
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
                    .font(.headline)
                Spacer()
                #if !os(watchOS)
                if errorMessage == nil, !output.isEmpty {
                    CopyButton(value: output)
                }
                #endif
            }

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
                        .fixedSize(horizontal: false, vertical: true)
                        #if !os(watchOS)
                        .textSelection(.enabled)
                        #endif
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            .padding(12)
            .background(
                .quaternary,
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
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
