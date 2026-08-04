import Foundation

nonisolated enum EFFPassphraseWordList {
    static func load(from bundle: Bundle = .main) throws -> [String] {
        let resourceURL = bundle.url(
            forResource: "eff_short_wordlist_1",
            withExtension: "txt",
            subdirectory: "Passphrases"
        ) ?? bundle.url(
            forResource: "eff_short_wordlist_1",
            withExtension: "txt"
        )

        guard let resourceURL else {
            throw PasswordGenerationError.wordListUnavailable
        }

        let content = try String(contentsOf: resourceURL, encoding: .utf8)
        let words = content.split(whereSeparator: \Character.isNewline).compactMap { line in
            line.split(whereSeparator: \Character.isWhitespace).last.map(String.init)
        }

        guard !words.isEmpty else {
            throw PasswordGenerationError.wordListUnavailable
        }
        return words
    }
}
