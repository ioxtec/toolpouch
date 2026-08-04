nonisolated enum PassphraseSeparator: String, CaseIterable, Identifiable, Sendable {
    case hyphen = "-"
    case underscore = "_"
    case period = "."
    case space = " "

    var id: Self { self }

    var title: String {
        switch self {
        case .hyphen: "Hyphen (-)"
        case .underscore: "Underscore (_)"
        case .period: "Period (.)"
        case .space: "Space"
        }
    }
}
