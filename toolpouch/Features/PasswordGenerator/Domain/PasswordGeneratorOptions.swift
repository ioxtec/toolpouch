nonisolated struct PasswordGeneratorOptions: Equatable, Sendable {
    let mode: PasswordGenerationMode
    let length: Int
    let wordCount: Int
    let separator: PassphraseSeparator
    let includesLowercase: Bool
    let includesUppercase: Bool
    let includesDigits: Bool
    let includesSymbols: Bool
    let avoidsAmbiguousCharacters: Bool
}
