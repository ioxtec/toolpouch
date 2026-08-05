#if os(macOS)
import SwiftUI

struct SSHKeysView: View {
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
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SSH Keys")
                        .font(.title2.bold())
                    Text("Manage key pairs stored in your SSH folder.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingGenerator = true
                } label: {
                    Image(systemName: "plus")
                        .toolPouchIcon(.medium)
                }
                .buttonStyle(.glass)
                .disabled(model.folderURL == nil || model.isLoading)
                .help("Generate SSH Key")
            }

            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .toolPouchIcon(.small)
                    .foregroundStyle(.secondary)
                Text(model.folderURL?.path(percentEncoded: false) ?? "No folder selected")
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(model.folderURL == nil ? "Choose Folder" : "Change") {
                    Task { await model.chooseFolder() }
                }
            }
        }
        .padding(ToolPouchLayout.Content.padding)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.isLoading, model.keys.isEmpty {
            ProgressView("Reading SSH keys…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.keys.isEmpty {
            ContentUnavailableView {
                Label("No SSH Keys", systemImage: "key.horizontal")
            } description: {
                Text("Generate a key pair or choose a different folder.")
            } actions: {
                Button("Generate Key") { isShowingGenerator = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    ForEach(model.keys) { key in
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
                    }
                } header: {
                    SSHKeyActionsHeader()
                }
            }
            .listStyle(.inset)
        }

        if let errorMessage = model.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }
}

private struct SSHKeyRow: View {
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
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(key.name)
                    .font(.headline)
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
            .frame(width: SSHKeyActionColumn.width)
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
            .frame(width: SSHKeyActionColumn.width)
            .help(
                privateKeyWasCopied ? "Private Key Copied" : "Copy Private Key"
            )
            .accessibilityLabel(
                privateKeyWasCopied ? "Private Key Copied" : "Copy Private Key"
            )

            Button(action: deleteKeyPair) {
                Image(systemName: "xmark.circle.fill")
                    .toolPouchIcon(.medium)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .frame(width: SSHKeyActionColumn.width)
            .help("Move Key Pair to Trash")
            .accessibilityLabel("Move Key Pair to Trash")
        }
        .padding(.vertical, 5)
    }
}

private struct SSHKeyActionsHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Key Pair")
            Spacer()
            SSHKeyActionColumnHeader(
                title: "PUB",
                systemImage: "doc.text"
            )
            SSHKeyActionColumnHeader(
                title: "PRV",
                systemImage: "lock.doc"
            )
            SSHKeyActionColumnHeader(
                title: "DEL",
                systemImage: "trash"
            )
        }
        .textCase(nil)
    }
}

private struct SSHKeyActionColumnHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .toolPouchIcon(.small)
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .frame(width: SSHKeyActionColumn.width)
        .accessibilityElement(children: .combine)
    }
}

private enum SSHKeyActionColumn {
    static let width: CGFloat = 38
}
#endif
