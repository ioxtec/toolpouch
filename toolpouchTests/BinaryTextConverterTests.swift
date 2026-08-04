import Testing
@testable import toolpouch

struct BinaryTextConverterTests {
    private let converter = BinaryTextConverter()

    @Test(
        arguments: [
            BinaryTextEncoding.base64,
            .base64URL,
            .base32,
            .hexadecimal,
        ]
    )
    func unicodeTextRoundTrips(encoding: BinaryTextEncoding) throws {
        let original = "ToolPouch — zażółć 🧰"
        let encoded = try converter.convert(
            original,
            using: encoding,
            direction: .encode
        )
        let decoded = try converter.convert(
            encoded,
            using: encoding,
            direction: .decode
        )

        #expect(decoded == original)
    }

    @Test(
        arguments: [
            (BinaryTextEncoding.base64, "aGVsbG8="),
            (.base64URL, "aGVsbG8"),
            (.base32, "NBSWY3DP"),
            (.hexadecimal, "68656c6c6f"),
        ]
    )
    func producesKnownEncoding(
        encoding: BinaryTextEncoding,
        expected: String
    ) throws {
        let result = try converter.convert(
            "hello",
            using: encoding,
            direction: .encode
        )

        #expect(result == expected)
    }

    @Test
    func base64URLUsesURLSafeAlphabetWithoutPadding() throws {
        let result = try converter.convert(
            "hello?",
            using: .base64URL,
            direction: .encode
        )

        #expect(result == "aGVsbG8_")
    }

    @Test
    func decodersAcceptCommonFormatting() throws {
        let base64 = try converter.convert(
            "aGVs\nbG8=",
            using: .base64,
            direction: .decode
        )
        let base32 = try converter.convert(
            "NBSW Y3DP====",
            using: .base32,
            direction: .decode
        )
        let hexadecimal = try converter.convert(
            "0x68 65 6c 6c 6f",
            using: .hexadecimal,
            direction: .decode
        )

        #expect(base64 == "hello")
        #expect(base32 == "hello")
        #expect(hexadecimal == "hello")
    }

    @Test
    func invalidEncodedInputThrows() {
        #expect(throws: TextEncodingConversionError.self) {
            try converter.convert(
                "not base64!",
                using: .base64,
                direction: .decode
            )
        }
    }
}
