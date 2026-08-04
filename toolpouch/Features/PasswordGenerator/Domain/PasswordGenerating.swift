nonisolated protocol PasswordGenerating: Sendable {
    func generate(options: PasswordGeneratorOptions) throws -> GeneratedPassword
}
