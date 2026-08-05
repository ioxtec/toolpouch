import Foundation
import Testing
@testable import toolpouch

struct FoundationJSONFormatterTests {
    private let formatter = FoundationJSONFormatter()

    @Test
    func prettyFormattingAddsReadableWhitespace() throws {
        let result = try formatter.format(
            #"{"name":"ToolPouch","enabled":true}"#,
            style: .pretty
        )

        #expect(result.contains("\n"))
        #expect(result.contains(#"  "name" : "ToolPouch""#))
    }

    @Test
    func compactFormattingRemovesInsignificantWhitespace() throws {
        let result = try formatter.format(
            """
            {
              "name": "ToolPouch",
              "values": [1, 2, 3]
            }
            """,
            style: .compact
        )

        #expect(!result.contains("\n"))
        #expect(!result.contains("  "))

        let value = try JSONSerialization.jsonObject(
            with: Data(result.utf8)
        ) as? [String: Any]
        #expect(value?["name"] as? String == "ToolPouch")
    }

    @Test
    func topLevelFragmentsAreSupported() throws {
        let result = try formatter.format(#""ToolPouch""#, style: .compact)

        #expect(result == #""ToolPouch""#)
    }

    @Test
    func unicodeAndSlashesRemainReadable() throws {
        let result = try formatter.format(
            #"{"message":"zażółć 🧰","url":"https://example.com"}"#,
            style: .compact
        )

        #expect(result.contains("zażółć 🧰"))
        #expect(result.contains("https://example.com"))
    }

    @Test
    func invalidJSONReturnsUsefulDetails() {
        #expect(throws: JSONFormattingError.self) {
            try formatter.format(#"{"name":}"#, style: .pretty)
        }
    }

    @Test
    func emptyInputIsRejected() {
        #expect(throws: JSONFormattingError.emptyInput) {
            try formatter.format("   \n", style: .pretty)
        }
    }
}
