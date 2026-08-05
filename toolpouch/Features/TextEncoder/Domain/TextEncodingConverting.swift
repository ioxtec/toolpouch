nonisolated protocol TextEncodingConverting: Sendable {
    /// Encodes plain text or decodes the selected binary-to-text representation.
    func convert(
        _ input: String,
        using encoding: BinaryTextEncoding,
        direction: TextConversionDirection
    ) throws -> String
}
