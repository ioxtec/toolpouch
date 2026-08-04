nonisolated enum PasswordGenerationMode: String, CaseIterable, Identifiable, Sendable {
    case random
    case passphrase

    var id: Self { self }

    var title: String {
        switch self {
        case .random: "Random"
        case .passphrase: "Passphrase"
        }
    }

}
