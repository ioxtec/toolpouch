nonisolated protocol TextEncodingConverting: Sendable {
    func convert(
        _ input: String,
        using encoding: BinaryTextEncoding,
        direction: TextConversionDirection
    ) throws -> String
}
