#if os(macOS)
import SwiftUI

struct SSHKeysView: View {
    @Environment(\.appTheme) private var theme
    @State private var model: SSHKeysViewModel
    @State private var isShowingGenerator = false
    @State private var keyPendingPrivateCopy: SSHKeyPair?
    @State private var keyPendingDeletion: SSHKeyPair?

    init(
        manager: any SSHKeyManaging,
        folderStore: any SSHKeyFolderAccessing
    ) {
        _model = State(
            initialValue: SSHKeysViewModel(
                manager: manager,
                folderStore: folderStore
            )
        )
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header
                folderControl
                content
            }
        }
        .scrollIndicators(.never)
        .task { await model.load() }
        .sheet(isPresented: $isShowingGenerator) {
            SSHKeyGeneratorView(model: model)
        }
        .alert(
            "Copy Private Key?",
            isPresented: Binding(
                get: { keyPendingPrivateCopy != nil },
                set: { if !$0 { keyPendingPrivateCopy = nil } }
            ),
            presenting: keyPendingPrivateCopy
        ) { key in
            Button("Cancel", role: .cancel) {}
            Button("Copy Private Key", role: .destructive) {
                Task { await model.copyPrivateKey(key) }
            }
        } message: { _ in
            Text("Anyone with this private key may be able to access your systems. Clear the clipboard after use.")
        }
        .alert(
            "Move Key Pair to Trash?",
            isPresented: Binding(
                get: { keyPendingDeletion != nil },
                set: { if !$0 { keyPendingDeletion = nil } }
            ),
            presenting: keyPendingDeletion
        ) { key in
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                Task { await model.moveKeyPairToTrash(key) }
            }
        } message: { key in
            Text("The private key \"\(key.name)\" and its public key will be moved to the Trash.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: ToolPouchLayout.Spacing.large) {
            ScreenHeader(
                title: "SSH Keys",
                subtitle: "Manage key pairs stored in your SSH folder."
            )

            Button {
                isShowingGenerator = true
            } label: {
                Label("Generate", systemImage: "plus")
            }
            .toolPouchPrimaryAction()
            .disabled(model.folderURL == nil || model.isLoading)
            .help("Generate SSH Key")
        }
    }

    private var folderControl: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            Image(systemName: "folder")
                .toolPouchIcon(.small, weight: .medium)
                .foregroundStyle(theme.colors.primaryAccent.color)

            Text(model.folderURL?.path(percentEncoded: false) ?? "No folder selected".localizedInterfaceText)
                .font(ToolPouchLayout.Typography.supporting.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: ToolPouchLayout.Spacing.medium)

            Button(model.folderURL == nil ? "Choose Folder" : "Change") {
                Task { await model.chooseFolder() }
            }
            .toolPouchSecondaryAction()
        }
        .padding(.horizontal, ToolPouchLayout.Spacing.large)
        .frame(minHeight: ToolPouchLayout.Control.regularHeight)
        .toolPouchSurface(interactive: true, cornerRadius: ToolPouchLayout.Radius.control)
    }

    @ViewBuilder
    private var content: some View {
        if model.folderURL == nil {
            ContentUnavailableView {
                Label("Choose Your SSH Folder", systemImage: "folder.badge.questionmark")
            } description: {
                Text("Select ~/.ssh or another folder to list and generate keys.")
            } actions: {
                Button("Choose Folder") {
                    Task { await model.chooseFolder() }
                }
                .toolPouchPrimaryAction()
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        } else if model.isLoading, model.keys.isEmpty {
            ProgressView("Reading SSH keys…")
                .frame(maxWidth: .infinity, minHeight: 150)
        } else if model.keys.isEmpty {
            ContentUnavailableView {
                Label("No SSH Keys", systemImage: "key.horizontal")
            } description: {
                Text("Generate a key pair or choose a different folder.")
            } actions: {
                Button("Generate Key") { isShowingGenerator = true }
                    .toolPouchPrimaryAction()
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        } else {
            ToolSectionCard("Key pairs") {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.keys.enumerated()), id: \.element.id) { index, key in
                        SSHKeyRow(
                            key: key,
                            publicKeyWasCopied: model.copiedKey
                                == .publicKey(key.id),
                            privateKeyWasCopied: model.copiedKey
                                == .privateKey(key.id),
                            copyPublicKey: {
                                Task { await model.copyPublicKey(key) }
                            },
                            copyPrivateKey: {
                                keyPendingPrivateCopy = key
                            },
                            deleteKeyPair: {
                                keyPendingDeletion = key
                            }
                        )
                        if index < model.keys.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }

        if let errorMessage = model.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(ToolPouchLayout.Typography.supporting)
                .foregroundStyle(theme.colors.danger.color)
        }
    }
}

private struct SSHKeyRow: View {
    @Environment(\.appTheme) private var theme
    let key: SSHKeyPair
    let publicKeyWasCopied: Bool
    let privateKeyWasCopied: Bool
    let copyPublicKey: () -> Void
    let copyPrivateKey: () -> Void
    let deleteKeyPair: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.horizontal")
                .toolPouchIcon(.medium)
                .foregroundStyle(theme.colors.primaryAccent.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(key.name)
                    .font(ToolPouchLayout.Typography.body.weight(.semibold))
                HStack(spacing: 8) {
                    if let algorithm = key.algorithm {
                        Text(algorithm)
                    }
                    if let comment = key.comment, !comment.isEmpty {
                        Text(comment)
                            .lineLimit(1)
                    }
                }
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: copyPublicKey) {
                Image(
                    systemName: publicKeyWasCopied
                        ? "checkmark"
                        : "doc.on.doc"
                )
                    .toolPouchIcon(.medium)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .frame(width: SSHKeyActionColumn.width, height: 28)
            .disabled(key.publicKeyURL == nil)
            .help(
                publicKeyWasCopied ? "Public Key Copied" : "Copy Public Key"
            )
            .accessibilityLabel(
                publicKeyWasCopied ? "Public Key Copied" : "Copy Public Key"
            )

            Button(action: copyPrivateKey) {
                Image(
                    systemName: privateKeyWasCopied
                        ? "checkmark"
                        : "doc.on.doc"
                )
                    .toolPouchIcon(.medium)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .frame(width: SSHKeyActionColumn.width, height: 28)
            .help(
                privateKeyWasCopied ? "Private Key Copied" : "Copy Private Key"
            )
            .accessibilityLabel(
                privateKeyWasCopied ? "Private Key Copied" : "Copy Private Key"
            )

            Button(action: deleteKeyPair) {
                Image(systemName: "xmark.circle.fill")
                    .toolPouchIcon(.medium)
                    .foregroundStyle(theme.colors.danger.color)
            }
            .buttonStyle(.borderless)
            .frame(width: SSHKeyActionColumn.width, height: 28)
            .help("Move Key Pair to Trash")
            .accessibilityLabel("Move Key Pair to Trash")
        }
        .padding(.vertical, ToolPouchLayout.Spacing.small)
    }
}

private enum SSHKeyActionColumn {
    static let width: CGFloat = 30
}
#endif
