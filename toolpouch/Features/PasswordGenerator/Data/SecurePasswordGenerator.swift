import Foundation

nonisolated struct SecurePasswordGenerator: PasswordGenerating {
    private enum CharacterSet {
        static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
        static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        static let digits = Array("0123456789")
        static let symbols = Array("!@#$%^&*+=?")
        static let ambiguous = Set("Il1O0o")
    }

    private let words: [String]

    init(words: [String]) {
        self.words = words
    }

    func generate(options: PasswordGeneratorOptions) throws -> GeneratedPassword {
        switch options.mode {
        case .random:
            try generateRandomPassword(options: options)
        case .passphrase:
            try generatePassphrase(options: options)
        }
    }

    private func generateRandomPassword(
        options: PasswordGeneratorOptions
    ) throws -> GeneratedPassword {
        var requiredSets: [[Character]] = []
        if options.includesLowercase { requiredSets.append(CharacterSet.lowercase) }
        if options.includesUppercase { requiredSets.append(CharacterSet.uppercase) }
        if options.includesDigits { requiredSets.append(CharacterSet.digits) }
        if options.includesSymbols { requiredSets.append(CharacterSet.symbols) }
        if options.avoidsAmbiguousCharacters {
            requiredSets = requiredSets.map { characters in
                characters.filter { !CharacterSet.ambiguous.contains($0) }
            }
        }

        guard !requiredSets.isEmpty else {
            throw PasswordGenerationError.noCharacterSetSelected
        }

        guard options.length >= requiredSets.count else {
            throw PasswordGenerationError.invalidLength
        }

        var generator = SystemRandomNumberGenerator()
        let pool = requiredSets.flatMap { $0 }
        var characters = requiredSets.map { randomElement(from: $0, using: &generator) }

        while characters.count < options.length {
            characters.append(randomElement(from: pool, using: &generator))
        }
        characters.shuffle(using: &generator)

        let entropy = Double(options.length) * log2(Double(pool.count))
        return GeneratedPassword(
            value: String(characters),
            estimatedEntropyBits: Int(entropy.rounded(.down)),
            wordCount: nil
        )
    }

    private func generatePassphrase(
        options: PasswordGeneratorOptions
    ) throws -> GeneratedPassword {
        guard !words.isEmpty else {
            throw PasswordGenerationError.wordListUnavailable
        }

        var generator = SystemRandomNumberGenerator()
        guard options.wordCount >= 3 else {
            throw PasswordGenerationError.invalidLength
        }

        var selectedWords: [String] = []
        while selectedWords.count < options.wordCount {
            selectedWords.append(randomElement(from: words, using: &generator))
        }
        let value = decorate(words: selectedWords, options: options, using: &generator)

        var entropy = Double(selectedWords.count) * log2(Double(words.count))
        if options.includesDigits {
            entropy += log2(10)
            entropy += log2(Double(selectedWords.count))
        }

        return GeneratedPassword(
            value: value,
            estimatedEntropyBits: Int(entropy.rounded(.down)),
            wordCount: selectedWords.count
        )
    }

    private func decorate<T: RandomNumberGenerator>(
        words: [String],
        options: PasswordGeneratorOptions,
        using generator: inout T
    ) -> String {
        var decoratedWords = words

        if options.includesUppercase {
            decoratedWords = decoratedWords.map(\.capitalized)
        }
        if options.includesDigits {
            let number = Int.random(in: 0...9, using: &generator)
            if let index = decoratedWords.indices.randomElement(using: &generator) {
                decoratedWords[index].append(String(number))
            }
        }

        return decoratedWords.joined(separator: options.separator.rawValue)
    }

    private func randomElement<T: RandomNumberGenerator>(
        from values: [Character],
        using generator: inout T
    ) -> Character {
        values[Int.random(in: values.indices, using: &generator)]
    }

    private func randomElement<T: RandomNumberGenerator>(
        from values: [String],
        using generator: inout T
    ) -> String {
        values[Int.random(in: values.indices, using: &generator)]
    }
}
