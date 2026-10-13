import Foundation

/// Release-specific links live in bundled JSON instead of SwiftUI views.
/// Missing or invalid URLs are never presented as working actions.
nonisolated struct ApplicationLinks: Decodable {
    let privacyPolicyURL: String?
    let supportURL: String?

    var privacyPolicy: URL? { validatedURL(privacyPolicyURL) }
    var support: URL? { validatedURL(supportURL) }

    static var current: ApplicationLinks {
        guard let url = Bundle.main.url(forResource: "ApplicationLinks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let links = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self(privacyPolicyURL: nil, supportURL: nil)
        }
        return links
    }

    private func validatedURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value),
              url.scheme == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }
}
