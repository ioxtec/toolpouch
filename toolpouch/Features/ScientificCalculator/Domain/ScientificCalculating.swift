nonisolated protocol ScientificCalculating: Sendable {
    /// Evaluates a local mathematical expression. Variables make the same
    /// engine reusable by the graphing tool without evaluating source code.
    func evaluate(
        _ expression: String,
        angleUnit: ScientificAngleUnit,
        variables: [String: Double]
    ) throws -> Double
}

extension ScientificCalculating {
    func evaluate(
        _ expression: String,
        angleUnit: ScientificAngleUnit
    ) throws -> Double {
        try evaluate(expression, angleUnit: angleUnit, variables: [:])
    }
}
