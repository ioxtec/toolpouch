nonisolated enum ScientificAngleUnit: String, CaseIterable, Identifiable, Sendable {
    case degrees
    case radians

    var id: Self { self }

    var title: String {
        switch self {
        case .degrees: "Degrees"
        case .radians: "Radians"
        }
    }
}
