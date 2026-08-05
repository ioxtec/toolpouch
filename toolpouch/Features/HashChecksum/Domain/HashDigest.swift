import Foundation

nonisolated struct HashDigest: Equatable, Sendable {
    let algorithm: HashAlgorithm
    let value: String

    func matches(_ expectedValue: String) -> Bool {
        let expected = normalized(expectedValue)
        let actual = normalized(value)

        guard expected.utf8.count == actual.utf8.count else { return false }

        var difference: UInt8 = 0
        for (actualByte, expectedByte) in zip(actual.utf8, expected.utf8) {
            difference |= actualByte ^ expectedByte
        }
        return difference == 0
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
