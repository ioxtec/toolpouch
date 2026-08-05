import Foundation

nonisolated protocol HTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

nonisolated struct URLSessionHTTPDataLoader: HTTPDataLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw DomainLookupError.invalidResponse
        }
        return (data, response)
    }
}

actor RDAPDomainLookupClient: DomainLookupService {
    private struct BootstrapResponse: Decodable {
        let services: [[[String]]]
    }

    private let loader: any HTTPDataLoading
    private let bootstrapURL: URL
    private var endpointsByTopLevelDomain: [String: URL]?

    init(
        loader: any HTTPDataLoading = URLSessionHTTPDataLoader(),
        bootstrapURL: URL = URL(string: "https://data.iana.org/rdap/dns.json")!
    ) {
        self.loader = loader
        self.bootstrapURL = bootstrapURL
    }

    func lookup(_ input: String) async throws -> DomainRegistration {
        let domain = try normalize(input)
        let topLevelDomain = domain.split(separator: ".").last.map(String.init) ?? ""
        let endpoint = try await endpoint(for: topLevelDomain)

        guard endpoint.scheme?.lowercased() == "https" else {
            throw DomainLookupError.insecureService
        }

        let lookupURL = endpoint
            .appendingPathComponent("domain", isDirectory: true)
            .appendingPathComponent(domain)
        var request = URLRequest(url: lookupURL)
        request.timeoutInterval = 12
        request.setValue(
            "application/rdap+json, application/json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await loader.data(for: request)
        try validate(response)

        let rdapResponse: RDAPDomainResponse
        do {
            rdapResponse = try JSONDecoder().decode(RDAPDomainResponse.self, from: data)
        } catch {
            throw DomainLookupError.invalidResponse
        }

        return makeRegistration(
            from: rdapResponse,
            queriedDomain: domain,
            sourceURL: lookupURL,
            rawData: data
        )
    }

    private func endpoint(for topLevelDomain: String) async throws -> URL {
        if endpointsByTopLevelDomain == nil {
            endpointsByTopLevelDomain = try await loadBootstrap()
        }

        guard let endpoint = endpointsByTopLevelDomain?[topLevelDomain] else {
            throw DomainLookupError.unsupportedTopLevelDomain(topLevelDomain)
        }
        return endpoint
    }

    private func loadBootstrap() async throws -> [String: URL] {
        var request = URLRequest(url: bootstrapURL)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await loader.data(for: request)
        try validate(response)

        let bootstrap: BootstrapResponse
        do {
            bootstrap = try JSONDecoder().decode(BootstrapResponse.self, from: data)
        } catch {
            throw DomainLookupError.invalidResponse
        }

        var endpoints: [String: URL] = [:]
        for service in bootstrap.services where service.count >= 2 {
            let topLevelDomains = service[0]
            let urls = service[1].compactMap(URL.init(string:))
            guard let endpoint = urls.first(where: { $0.scheme == "https" })
                ?? urls.first else {
                continue
            }

            for topLevelDomain in topLevelDomains {
                endpoints[topLevelDomain.lowercased()] = endpoint
            }
        }
        return endpoints
    }

    private func normalize(_ input: String) throws -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw DomainLookupError.invalidDomain }

        if !value.contains("://") {
            value = "https://\(value)"
        }

        guard let components = URLComponents(string: value),
              let host = components.host?.lowercased() else {
            throw DomainLookupError.invalidDomain
        }

        let domain = host.hasSuffix(".") ? String(host.dropLast()) : host
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2,
              labels.allSatisfy({ !$0.isEmpty }),
              !domain.contains(" ") else {
            throw DomainLookupError.invalidDomain
        }
        return domain
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 404:
            throw DomainLookupError.notFound
        case 429:
            throw DomainLookupError.rateLimited
        default:
            throw DomainLookupError.serverError(response.statusCode)
        }
    }

    private func makeRegistration(
        from response: RDAPDomainResponse,
        queriedDomain: String,
        sourceURL: URL,
        rawData: Data
    ) -> DomainRegistration {
        let registrar = response.entities?.first {
            $0.roles?.contains("registrar") == true
        }
        let events = response.events ?? []
        let rawResponse: String

        if let object = try? JSONSerialization.jsonObject(with: rawData),
           let prettyData = try? JSONSerialization.data(
               withJSONObject: object,
               options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
           ) {
            rawResponse = String(decoding: prettyData, as: UTF8.self)
        } else {
            rawResponse = String(decoding: rawData, as: UTF8.self)
        }

        return DomainRegistration(
            name: response.ldhName ?? queriedDomain,
            unicodeName: response.unicodeName,
            registryHandle: response.handle,
            registrarName: registrar?.displayName,
            registrarHandle: registrar?.handle,
            registeredAt: date(for: "registration", in: events),
            expiresAt: date(for: "expiration", in: events),
            lastChangedAt: date(for: "last changed", in: events),
            nameservers: (response.nameservers ?? [])
                .compactMap { $0.unicodeName ?? $0.ldhName }
                .map { $0.lowercased() }
                .sorted(),
            statuses: (response.status ?? []).sorted(),
            isDNSSECSigned: response.secureDNS?.delegationSigned,
            notices: messages(from: response.notices) + messages(from: response.remarks),
            sourceURL: sourceURL,
            rawResponse: rawResponse
        )
    }

    private func date(
        for action: String,
        in events: [RDAPDomainResponse.Event]
    ) -> Date? {
        guard let value = events.first(where: {
            $0.eventAction.caseInsensitiveCompare(action) == .orderedSame
        })?.eventDate else {
            return nil
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractionalFormatter.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
    }

    private func messages(from values: [RDAPDomainResponse.Message]?) -> [String] {
        (values ?? []).flatMap { message in
            let descriptions = message.description ?? []
            if descriptions.isEmpty, let title = message.title {
                return [title]
            }
            return descriptions
        }
    }
}
