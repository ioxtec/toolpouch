import Testing
@testable import toolpouch

struct SecurePasswordGeneratorTests {
    private let generator = SecurePasswordGenerator(
        words: [
            "amber", "cabin", "drift", "ember", "forest", "globe",
            "harbor", "island", "jungle", "kitten", "lemon", "meadow",
        ]
    )

    @Test
    func randomPasswordHasExactLengthAndEverySelectedCharacterClass() throws {
        let result = try generator.generate(
            options: options(mode: .random, length: 32)
        )

        #expect(result.value.count == 32)
        #expect(result.value.contains { $0.isLowercase })
        #expect(result.value.contains { $0.isUppercase })
        #expect(result.value.contains { $0.isNumber })
        #expect(result.value.contains { "!@#$%^&*+=?".contains($0) })
        #expect(result.wordCount == nil)
    }

    @Test
    func randomPasswordHonorsDisabledCharacterClasses() throws {
        let result = try generator.generate(
            options: options(
                mode: .random,
                length: 24,
                includesLowercase: true,
                includesUppercase: false,
                includesDigits: false,
                includesSymbols: false
            )
        )

        #expect(result.value.count == 24)
        #expect(result.value.allSatisfy { $0.isLowercase })
    }

    @Test
    func randomPasswordCanAvoidAmbiguousCharacters() throws {
        let result = try generator.generate(
            options: options(mode: .random, length: 128)
        )

        #expect(result.value.allSatisfy { !"Il1O0o".contains($0) })
    }

    @Test
    func passphraseUsesWholeWordsAndSelectedSeparator() throws {
        let result = try generator.generate(
            options: options(
                mode: .passphrase,
                wordCount: 6,
                separator: .underscore,
                includesUppercase: false,
                includesDigits: false,
                includesSymbols: false
            )
        )

        #expect(result.wordCount == 6)
        #expect(result.value.split(separator: "_").count == 6)
        #expect(!result.value.contains("-"))
    }

    @Test
    func passphraseIncludesRequestedDecorations() throws {
        let result = try generator.generate(
            options: options(mode: .passphrase, wordCount: 6)
        )

        #expect(result.value.contains { $0.isUppercase })
        #expect(result.value.contains { $0.isNumber })
        #expect(!result.value.contains { "!@#$%^&*+=?".contains($0) })
        #expect(result.value.split(separator: "-").count == 6)
        #expect(
            result.value.split(separator: "-").allSatisfy {
                $0.first?.isUppercase == true
            }
        )
        #expect(result.wordCount == 6)
    }

    private func options(
        mode: PasswordGenerationMode,
        length: Int = 20,
        wordCount: Int = 6,
        separator: PassphraseSeparator = .hyphen,
        includesLowercase: Bool = true,
        includesUppercase: Bool = true,
        includesDigits: Bool = true,
        includesSymbols: Bool = true
    ) -> PasswordGeneratorOptions {
        PasswordGeneratorOptions(
            mode: mode,
            length: length,
            wordCount: wordCount,
            separator: separator,
            includesLowercase: includesLowercase,
            includesUppercase: includesUppercase,
            includesDigits: includesDigits,
            includesSymbols: includesSymbols,
            avoidsAmbiguousCharacters: true
        )
    }
}
