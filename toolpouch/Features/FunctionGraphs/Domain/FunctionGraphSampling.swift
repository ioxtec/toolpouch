nonisolated protocol FunctionGraphSampling: Sendable {
    func sample(
        expression: String,
        xRange: ClosedRange<Double>,
        angleUnit: ScientificAngleUnit,
        sampleCount: Int
    ) throws -> FunctionGraph
}
