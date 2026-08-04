import Foundation

nonisolated struct PublicIPAddressClient: Sendable {
    private struct Response: Decodable {
        let ip: String
    }

    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.ipify.org?format=json")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func fetch() async throws -> String {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 8

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Response.self, from: data).ip
    }
}
