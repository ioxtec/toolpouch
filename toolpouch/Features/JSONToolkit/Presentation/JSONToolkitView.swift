import SwiftUI

struct JSONToolkitView: View {
    private let formatter: any JSONFormatting

    @State private var style: JSONFormattingStyle = .pretty
    @State private var input = ""
    @State private var output = ""
    @State private var errorMessage: String?

    init(formatter: any JSONFormatting) {
        self.formatter = formatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "JSON Toolkit",
                    subtitle: "Format, compact, and validate JSON without uploading it."
                )
                editorPanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .onChange(of: request, initial: true) {
            updateOutput()
        }
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            stylePicker
            Divider()
            inputSection
            validationStatus
            Divider()
            outputSection
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var stylePicker: some View {
        Picker("Output Style", selection: $style) {
            ForEach(JSONFormattingStyle.allCases) { style in
                Text(style.title).tag(style)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input")
                    .font(.headline)
                Spacer()
                if !input.isEmpty {
                    Button("Clear") { input = "" }
                        .buttonStyle(.borderless)
                }
            }

            TextEditor(text: $input)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 120)
                .background(
                    .quaternary,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .accessibilityLabel("JSON input")
        }
    }

    @ViewBuilder
    private var validationStatus: some View {
        if input.isEmpty {
            Label("Paste or type JSON to begin", systemImage: "curlybraces")
                .foregroundStyle(.secondary)
        } else if let errorMessage {
            Label(errorMessage, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .textSelection(.enabled)
        } else {
            Label("Valid JSON", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                if errorMessage == nil, !output.isEmpty {
                    CopyButton(value: output)
                }
            }

            ScrollView([.horizontal, .vertical]) {
                Text(output.isEmpty ? "The formatted JSON appears here." : output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(
                        output.isEmpty
                            ? Color.secondary.opacity(0.6)
                            : Color.primary
                    )
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 100, idealHeight: 160, maxHeight: 260)
            .padding(12)
            .background(
                .quaternary,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .accessibilityLabel("Formatted JSON output")
        }
    }

    private var request: JSONFormattingRequest {
        JSONFormattingRequest(input: input, style: style)
    }

    private func updateOutput() {
        guard !input.isEmpty else {
            output = ""
            errorMessage = nil
            return
        }

        do {
            output = try formatter.format(input, style: style)
            errorMessage = nil
        } catch {
            output = ""
            errorMessage = error.localizedDescription
        }
    }
}

private struct JSONFormattingRequest: Equatable {
    let input: String
    let style: JSONFormattingStyle
}
