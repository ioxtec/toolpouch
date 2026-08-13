import Foundation

/// Accepts coordinates copied from common map services in DD, DDM, or DMS notation.
nonisolated enum CoordinateParser {
    static func parse(_ input: String) -> GeographicCoordinate? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let coordinate = parseDirectional(trimmed) ?? parseDecimal(trimmed),
           coordinate.isValid {
            return coordinate
        }
        return nil
    }

    private static func parseDecimal(_ input: String) -> GeographicCoordinate? {
        let components: [Substring]
        if input.contains(";") {
            components = input.split(separator: ";", omittingEmptySubsequences: true)
        } else if input.filter({ $0 == "," }).count == 1 {
            components = input.split(separator: ",", omittingEmptySubsequences: true)
        } else {
            components = input.split(whereSeparator: { $0.isWhitespace })
        }

        guard components.count == 2,
              let latitude = number(String(components[0])),
              let longitude = number(String(components[1])) else {
            return nil
        }
        return GeographicCoordinate(latitude: latitude, longitude: longitude)
    }

    private static func parseDirectional(_ input: String) -> GeographicCoordinate? {
        // Each match represents one axis, for example 52° 13′ 46.8″ N.
        let pattern = #"(?i)([+-]?\d+(?:[\.,]\d+)?)\s*(?:°|deg)?\s*(?:(\d+(?:[\.,]\d+)?)\s*(?:['′]|min))?\s*(?:(\d+(?:[\.,]\d+)?)\s*(?:[\"″]|sec))?\s*([NSEW])"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        let matches = expression.matches(in: input, range: range)
        guard matches.count == 2 else { return nil }

        var latitude: Double?
        var longitude: Double?

        for match in matches {
            guard let degrees = capturedNumber(at: 1, match: match, input: input),
                  let hemisphere = capturedText(at: 4, match: match, input: input)?.uppercased() else {
                return nil
            }
            let minutes = capturedNumber(at: 2, match: match, input: input) ?? 0
            let seconds = capturedNumber(at: 3, match: match, input: input) ?? 0
            guard minutes >= 0, minutes < 60, seconds >= 0, seconds < 60 else {
                return nil
            }

            let absolute = abs(degrees) + minutes / 60 + seconds / 3_600
            let signed = hemisphere == "S" || hemisphere == "W" ? -absolute : absolute
            if hemisphere == "N" || hemisphere == "S" {
                latitude = signed
            } else {
                longitude = signed
            }
        }

        guard let latitude, let longitude else { return nil }
        return GeographicCoordinate(latitude: latitude, longitude: longitude)
    }

    private static func capturedText(
        at index: Int,
        match: NSTextCheckingResult,
        input: String
    ) -> String? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: input) else {
            return nil
        }
        return String(input[swiftRange])
    }

    private static func capturedNumber(
        at index: Int,
        match: NSTextCheckingResult,
        input: String
    ) -> Double? {
        capturedText(at: index, match: match, input: input).flatMap(number)
    }

    private static func number(_ text: String) -> Double? {
        Double(
            text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )
    }
}
