nonisolated enum JSONFormattingStyle: String, CaseIterable, Identifiable, Sendable {
    case pretty
    case compact

    var id: Self { self }

    var title: String {
        switch self {
        case .pretty: "Pretty"
        case .compact: "Compact"
        }
    }
}
