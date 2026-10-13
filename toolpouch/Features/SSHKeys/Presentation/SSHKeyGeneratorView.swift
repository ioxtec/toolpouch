#if os(macOS)
import SwiftUI

struct SSHKeyGeneratorView: View {
    let model: SSHKeysViewModel

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var algorithm: SSHKeyAlgorithm = .ed25519
    @State private var bitSize = 4096
    @State private var fileName = SSHKeyAlgorithm.ed25519.defaultFileName
    @State private var comment = ""
    @State private var passphrase = ""
    @State private var confirmedPassphrase = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Picker(selection: $algorithm) {
                    ForEach(SSHKeyAlgorithm.allCases) { algorithm in
                        Text(algorithm.title.localizedInterfaceText).tag(algorithm)
                    }
                } label: {
                    Text("Key Type".localizedInterfaceText)
                }

                if !algorithm.supportedBitSizes.isEmpty {
                    Picker(selection: $bitSize) {
                        ForEach(algorithm.supportedBitSizes, id: \.self) { size in
                            Text("\(size) bits").tag(size)
                        }
                    } label: {
                        Text("Key Size".localizedInterfaceText)
                    }
                }

                TextField("File Name".localizedInterfaceText, text: $fileName)
                    .textContentType(.none)

                TextField("Email or Comment".localizedInterfaceText, text: $comment)
                    .textContentType(.emailAddress)

                SecureField("Passphrase (Optional)".localizedInterfaceText, text: $passphrase)
                SecureField("Confirm Passphrase".localizedInterfaceText, text: $confirmedPassphrase)

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel".localizedInterfaceText, role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Generate Key".localizedInterfaceText) {
                    generate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(validationMessage != nil || isGenerating)
            }
            .padding()
        }
        .frame(width: 420, height: 390)
        .navigationTitle("Generate SSH Key".localizedInterfaceText)
        .id(languageStore.selection)
        .onChange(of: algorithm) { oldValue, newValue in
            if fileName == oldValue.defaultFileName {
                fileName = newValue.defaultFileName
            }
            if let preferredSize = newValue.supportedBitSizes.last {
                bitSize = preferredSize
            }
        }
    }

    private var validationMessage: String? {
        if fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a file name."
        }
        if fileName.contains("/") || fileName == "." || fileName == ".." {
            return "The file name cannot contain a path."
        }
        if passphrase != confirmedPassphrase {
            return "Passphrases do not match."
        }
        return nil
    }

    private func generate() {
        guard validationMessage == nil else { return }
        isGenerating = true
        errorMessage = nil

        let request = SSHKeyGenerationRequest(
            algorithm: algorithm,
            bitSize: algorithm.supportedBitSizes.isEmpty ? nil : bitSize,
            fileName: fileName,
            comment: comment,
            passphrase: passphrase
        )

        Task {
            do {
                try await model.generate(request)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
}
#endif
