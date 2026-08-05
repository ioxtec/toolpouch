nonisolated protocol UnitConverting: Sendable {
    /// Converts a value between compatible units and rejects mismatched measurement categories.
    func convert(
        _ value: Double,
        from source: ConversionUnit,
        to destination: ConversionUnit
    ) throws -> Double
}
