import Foundation

nonisolated struct NetworkCheckRequest: Equatable, Sendable {
    let host: String
    let port: UInt16

    init(host input: String, port: Int) throws {
        let host = Self.normalizedHost(from: input)
        guard !host.isEmpty, !host.contains(where: { $0.isWhitespace }) else {
            throw NetworkCheckError.invalidHost
        }
        guard (1...65_535).contains(port), let port = UInt16(exactly: port) else {
            throw NetworkCheckError.invalidPort
        }

        self.host = host
        self.port = port
    }

    private static func normalizedHost(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let components = URLComponents(string: trimmed),
           let host = components.host {
            return host.trimmingCharacters(
                in: CharacterSet(charactersIn: "[]")
            )
        }

        if let components = URLComponents(string: "//\(trimmed)"),
           let host = components.host {
            return host.trimmingCharacters(
                in: CharacterSet(charactersIn: "[]")
            )
        }

        return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }
}
