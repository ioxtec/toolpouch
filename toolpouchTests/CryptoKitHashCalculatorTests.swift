import Foundation
import Testing
@testable import toolpouch

struct CryptoKitHashCalculatorTests {
    private let calculator = CryptoKitHashCalculator()

    @Test(
        arguments: [
            (
                HashAlgorithm.sha256,
                "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
            ),
            (
                .sha512,
                "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca7"
                    + "2323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043"
            ),
            (.md5, "5d41402abc4b2a76b9719d911017c592"),
        ]
    )
    func producesKnownDigest(
        algorithm: HashAlgorithm,
        expected: String
    ) {
        let digest = calculator.hash(Data("hello".utf8), using: algorithm)

        #expect(digest.value == expected)
    }

    @Test
    func hashesFilesWithoutChangingTheResult() async throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ToolPouchHashTest-\(UUID().uuidString).txt")
        try Data("hello".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let digest = try await calculator.hash(fileAt: url, using: .sha256)

        #expect(
            digest.value
                == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        )
    }

    @Test
    func comparisonIgnoresCaseAndOuterWhitespace() {
        let digest = HashDigest(algorithm: .md5, value: "5d41402abc4b2a76b9719d911017c592")

        #expect(digest.matches("  5D41402ABC4B2A76B9719D911017C592\n"))
        #expect(!digest.matches("5d41402abc4b2a76b9719d911017c593"))
        #expect(!digest.matches("short"))
    }
}
