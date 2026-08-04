import SwiftUI

struct PasswordResultField: View {
    let password: GeneratedPassword?
    let errorMessage: String?
    let onRegenerate: () -> Void

    @State private var isHoveringPassword = false
    @State private var isShowingCopyConfirmation = false
    @State private var copyConfirmationID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let password {
                passwordField(for: password)
                metadata(for: password)
            } else if let errorMessage {
                errorField(message: errorMessage)
            }
        }
        .onChange(of: password?.value) {
            isShowingCopyConfirmation = false
        }
    }

    private func passwordField(for password: GeneratedPassword) -> some View {
        ZStack {
            HStack(alignment: .center, spacing: 12) {
                passwordValue(password.value)

                Button(action: onRegenerate) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Generate Again")
                .accessibilityLabel("Generate Again")

                #if !os(watchOS)
                Button {
                    copy(password.value)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy to Clipboard")
                .accessibilityLabel("Copy to Clipboard")
                #endif
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                .quaternary,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHoveringPassword
                            ? Color.secondary.opacity(0.35)
                            : .clear,
                        lineWidth: 1
                    )
            }

            if isShowingCopyConfirmation {
                Label("Copied", systemImage: "doc.on.doc.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8, y: 3)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isHoveringPassword)
        .animation(.easeInOut(duration: 0.18), value: isShowingCopyConfirmation)
    }

    @ViewBuilder
    private func passwordValue(_ value: String) -> some View {
        #if os(watchOS)
        passwordText(value)
            .frame(maxWidth: .infinity, alignment: .leading)
        #else
        Button {
            copy(value)
        } label: {
            passwordText(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click to Copy")
        .accessibilityLabel("Copy Password")
        #if os(macOS)
        .onHover { isHoveringPassword = $0 }
        #endif
        #endif
    }

    private func passwordText(_ value: String) -> some View {
        Text(value)
            #if os(watchOS)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            #else
            .font(.system(.body, design: .monospaced, weight: .medium))
            #endif
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorField(message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                .quaternary,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }

    private func metadata(for password: GeneratedPassword) -> some View {
        ViewThatFits(in: .horizontal) {
            metadataContent(for: password)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 10) {
                    Label(
                        "\(password.value.count) characters",
                        systemImage: "character.cursor.ibeam"
                    )
                    if let wordCount = password.wordCount {
                        Text("\(wordCount) words")
                    }
                }
                Text("~\(password.estimatedEntropyBits) bits")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func metadataContent(for password: GeneratedPassword) -> some View {
        HStack(spacing: 10) {
            Label(
                "\(password.value.count) characters",
                systemImage: "character.cursor.ibeam"
            )
            if let wordCount = password.wordCount {
                Text("\(wordCount) words")
            }
            Text("~\(password.estimatedEntropyBits) bits")
            Spacer(minLength: 0)
        }
    }

    private func copy(_ value: String) {
        SystemClipboard.copy(value)

        let confirmationID = UUID()
        copyConfirmationID = confirmationID
        isShowingCopyConfirmation = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard copyConfirmationID == confirmationID else { return }
            isShowingCopyConfirmation = false
        }
    }
}
