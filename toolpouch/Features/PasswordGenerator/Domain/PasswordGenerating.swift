nonisolated protocol PasswordGenerating: Sendable {
    /// Creates a password or passphrase from validated options using secure randomness.
    func generate(options: PasswordGeneratorOptions) throws -> GeneratedPassword
}
