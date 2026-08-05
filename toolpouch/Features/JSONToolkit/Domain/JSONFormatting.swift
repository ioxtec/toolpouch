nonisolated protocol JSONFormatting: Sendable {
    /// Validates JSON and returns it in the requested readable or compact form.
    func format(_ input: String, style: JSONFormattingStyle) throws -> String
}
