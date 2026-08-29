import Foundation

nonisolated struct SVGMetadataParser: Sendable {
    func dimensions(at url: URL) throws -> String? {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let prefix = data.prefix(131_072)
        guard let source = String(data: prefix, encoding: .utf8),
              let root = firstMatch(#"<svg\b[^>]*>"#, in: source, options: [.caseInsensitive]) else {
            throw MediaFileInspectionError.unreadableFile
        }

        if let width = attribute("width", in: root),
           let height = attribute("height", in: root) {
            return "\(formatLength(width)) × \(formatLength(height))"
        }

        if let viewBox = attribute("viewBox", in: root) {
            let values = viewBox
                .split(whereSeparator: { $0.isWhitespace || $0 == "," })
                .compactMap { Double($0) }
            if values.count == 4 {
                return "\(formatNumber(values[2])) × \(formatNumber(values[3])) viewBox"
            }
        }
        return nil
    }

    private func attribute(_ name: String, in root: String) -> String? {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let pattern = #"\b"# + escapedName + #"\s*=\s*["']([^"']+)["']"#
        guard let match = firstMatch(pattern, in: root, options: [.caseInsensitive], group: 1) else {
            return nil
        }
        return match.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstMatch(
        _ pattern: String,
        in string: String,
        options: NSRegularExpression.Options,
        group: Int = 0
    ) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(
                  in: string,
                  range: NSRange(string.startIndex..., in: string)
              ),
              let range = Range(match.range(at: group), in: string) else {
            return nil
        }
        return String(string[range])
    }

    private func formatLength(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let unitlessPattern = #"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$"#
        if firstMatch(unitlessPattern, in: trimmed, options: []) != nil {
            return "\(trimmed) px"
        }
        return trimmed
    }

    private func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...3)))
    }
}
