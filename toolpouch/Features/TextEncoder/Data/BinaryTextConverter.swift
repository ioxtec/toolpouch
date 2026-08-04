import Foundation

nonisolated struct BinaryTextConverter: TextEncodingConverting {
    private static let base32Alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8)

    func convert(
        _ input: String,
        using encoding: BinaryTextEncoding,
        direction: TextConversionDirection
    ) throws -> String {
        switch direction {
        case .encode:
            encode(Data(input.utf8), using: encoding)
        case .decode:
            try decodeText(input, using: encoding)
        }
    }

    private func encode(
        _ data: Data,
        using encoding: BinaryTextEncoding
    ) -> String {
        switch encoding {
        case .base64:
            data.base64EncodedString()
        case .base64URL:
            data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        case .base32:
            encodeBase32(data)
        case .hexadecimal:
            data.map { String(format: "%02x", $0) }.joined()
        }
    }

    private func decodeText(
        _ input: String,
        using encoding: BinaryTextEncoding
    ) throws -> String {
        let data: Data

        switch encoding {
        case .base64:
            guard let decoded = Data(
                base64Encoded: removingWhitespace(from: input)
            ) else {
                throw TextEncodingConversionError.invalidEncodedValue(encoding)
            }
            data = decoded
        case .base64URL:
            data = try decodeBase64URL(input)
        case .base32:
            data = try decodeBase32(input)
        case .hexadecimal:
            data = try decodeHexadecimal(input)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw TextEncodingConversionError.invalidUTF8
        }
        return text
    }

    private func decodeBase64URL(_ input: String) throws -> Data {
        var normalized = removingWhitespace(from: input)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        guard normalized.count % 4 != 1 else {
            throw TextEncodingConversionError.invalidEncodedValue(.base64URL)
        }
        normalized.append(
            String(repeating: "=", count: (4 - normalized.count % 4) % 4)
        )

        guard let data = Data(base64Encoded: normalized) else {
            throw TextEncodingConversionError.invalidEncodedValue(.base64URL)
        }
        return data
    }

    private func encodeBase32(_ data: Data) -> String {
        var result = [UInt8]()
        var buffer = 0
        var bitCount = 0

        for byte in data {
            buffer = (buffer << 8) | Int(byte)
            bitCount += 8

            while bitCount >= 5 {
                bitCount -= 5
                result.append(Self.base32Alphabet[(buffer >> bitCount) & 31])
            }

            if bitCount == 0 {
                buffer = 0
            } else {
                buffer &= (1 << bitCount) - 1
            }
        }

        if bitCount > 0 {
            result.append(Self.base32Alphabet[(buffer << (5 - bitCount)) & 31])
        }

        return String(decoding: result, as: UTF8.self)
    }

    private func decodeBase32(_ input: String) throws -> Data {
        let normalized = input.uppercased().filter {
            !$0.isWhitespace && $0 != "="
        }
        guard ![1, 3, 6].contains(normalized.count % 8) else {
            throw TextEncodingConversionError.invalidEncodedValue(.base32)
        }

        let lookup = Dictionary(
            uniqueKeysWithValues: Self.base32Alphabet.enumerated().map {
                ($0.element, $0.offset)
            }
        )
        var bytes = [UInt8]()
        var buffer = 0
        var bitCount = 0

        for character in normalized.utf8 {
            guard let value = lookup[character] else {
                throw TextEncodingConversionError.invalidEncodedValue(.base32)
            }

            buffer = (buffer << 5) | value
            bitCount += 5

            if bitCount >= 8 {
                bitCount -= 8
                bytes.append(UInt8((buffer >> bitCount) & 0xff))
                buffer &= bitCount == 0 ? 0 : (1 << bitCount) - 1
            }
        }

        guard buffer == 0 else {
            throw TextEncodingConversionError.invalidEncodedValue(.base32)
        }
        return Data(bytes)
    }

    private func decodeHexadecimal(_ input: String) throws -> Data {
        var normalized = removingWhitespace(from: input)
        if normalized.hasPrefix("0x") || normalized.hasPrefix("0X") {
            normalized.removeFirst(2)
        }

        let characters = Array(normalized.utf8)
        guard characters.count.isMultiple(of: 2) else {
            throw TextEncodingConversionError.invalidEncodedValue(.hexadecimal)
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / 2)

        for index in stride(from: 0, to: characters.count, by: 2) {
            guard
                let high = hexadecimalValue(of: characters[index]),
                let low = hexadecimalValue(of: characters[index + 1])
            else {
                throw TextEncodingConversionError.invalidEncodedValue(.hexadecimal)
            }
            bytes.append((high << 4) | low)
        }
        return Data(bytes)
    }

    private func hexadecimalValue(of character: UInt8) -> UInt8? {
        switch character {
        case 48...57: character - 48
        case 65...70: character - 55
        case 97...102: character - 87
        default: nil
        }
    }

    private func removingWhitespace(from value: String) -> String {
        value.filter { !$0.isWhitespace }
    }
}
