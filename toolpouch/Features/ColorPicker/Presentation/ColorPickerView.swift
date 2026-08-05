#if os(macOS)
import SwiftUI

struct ColorPickerView: View {
    @State private var session = ColorPickerSession.shared
    @State private var permission = ScreenCapturePermissionManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Color Picker",
                    subtitle: "Magnify the area around the pointer and select an exact pixel."
                )

                VStack(alignment: .leading, spacing: 14) {
                    colorPreview
                    Button {
                        startPicking()
                    } label: {
                        Label(
                            session.isPicking ? "Picking…" : "Pick a Color",
                            systemImage: "eyedropper"
                        )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(session.isPicking)

                    if let errorMessage = session.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)

                        Button("Open Permission Settings") {
                            permission.openSystemSettings()
                        }
                        .buttonStyle(.borderless)
                    }

                    Label(
                        "While picking, click to select a pixel or press Escape to cancel.",
                        systemImage: "scope"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .onAppear { permission.refresh() }
    }

    @ViewBuilder
    private var colorPreview: some View {
        if let selectedColor = session.selectedColor {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color(
                            red: Double(selectedColor.red) / 255,
                            green: Double(selectedColor.green) / 255,
                            blue: Double(selectedColor.blue) / 255
                        )
                    )
                    .frame(width: 86, height: 86)
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)) }

                VStack(alignment: .leading, spacing: 8) {
                    colorValue("HEX", selectedColor.hex)
                    colorValue("RGB", selectedColor.rgb)
                    colorValue("HSL", selectedColor.hsl)
                }
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "eyedropper.halffull")
                    .toolPouchIcon(.large, weight: .medium)
                Text("No color selected")
                    .font(.headline)
                Text("The selected color and its values will appear here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 130)
        }
    }

    private func colorValue(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
            CopyButton(value: value)
        }
    }

    private func startPicking() {
        permission.refresh()
        session.start()
    }
}
#endif
