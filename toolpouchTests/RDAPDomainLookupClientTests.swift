import Foundation
import Testing
@testable import toolpouch

struct RDAPDomainLookupClientTests {
    @Test
    func resolvesRegistryAndParsesDomainData() async throws {
        let bootstrapURL = try #require(URL(string: "https://bootstrap.test/dns.json"))
        let lookupURL = try #require(URL(string: "https://rdap.test/domain/example.com"))
        let loader = StubHTTPDataLoader(responses: [
            bootstrapURL: .ok(bootstrapJSON),
            lookupURL: .ok(domainJSON),
        ])
        let client = RDAPDomainLookupClient(loader: loader, bootstrapURL: bootstrapURL)

        let registration = try await client.lookup("https://Example.COM/path")

        #expect(registration.name == "EXAMPLE.COM")
        #expect(registration.registrarName == "Example Registrar")
        #expect(registration.nameservers == ["ns1.example.com", "ns2.example.com"])
        #expect(registration.isDNSSECSigned == true)
        #expect(registration.registeredAt != nil)
        #expect(registration.expiresAt != nil)
    }

    @Test
    func reportsUnsupportedTopLevelDomain() async throws {
        let bootstrapURL = try #require(URL(string: "https://bootstrap.test/dns.json"))
        let loader = StubHTTPDataLoader(responses: [bootstrapURL: .ok(bootstrapJSON)])
        let client = RDAPDomainLookupClient(loader: loader, bootstrapURL: bootstrapURL)

        await #expect(throws: DomainLookupError.unsupportedTopLevelDomain("invalid")) {
            try await client.lookup("example.invalid")
        }
    }

    @Test
    func mapsRegistryRateLimit() async throws {
        let bootstrapURL = try #require(URL(string: "https://bootstrap.test/dns.json"))
        let lookupURL = try #require(URL(string: "https://rdap.test/domain/example.com"))
        let loader = StubHTTPDataLoader(responses: [
            bootstrapURL: .ok(bootstrapJSON),
            lookupURL: StubResponse(statusCode: 429, data: Data()),
        ])
        let client = RDAPDomainLookupClient(loader: loader, bootstrapURL: bootstrapURL)

        await #expect(throws: DomainLookupError.rateLimited) {
            try await client.lookup("example.com")
        }
    }

    private var bootstrapJSON: Data {
        Data(#"{"services":[[["com"],["https://rdap.test/"]]]}"#.utf8)
    }

    private var domainJSON: Data {
        Data(
            #"""
            {
              "ldhName": "EXAMPLE.COM",
              "handle": "12345_DOMAIN_COM-VRSN",
              "status": ["client transfer prohibited"],
              "events": [
                {"eventAction": "registration", "eventDate": "1995-08-14T04:00:00Z"},
                {"eventAction": "expiration", "eventDate": "2027-08-13T04:00:00Z"}
              ],
              "entities": [{
                "handle": "376",
                "roles": ["registrar"],
                "vcardArray": ["vcard", [["fn", {}, "text", "Example Registrar"]]]
              }],
              "nameservers": [
                {"ldhName": "NS2.EXAMPLE.COM"},
                {"ldhName": "NS1.EXAMPLE.COM"}
              ],
              "secureDNS": {"delegationSigned": true}
            }
            """#.utf8
        )
    }
}

private struct StubResponse: Sendable {
    let statusCode: Int
    let data: Data

    static func ok(_ data: Data) -> StubResponse {
        StubResponse(statusCode: 200, data: data)
    }
}

private actor StubHTTPDataLoader: HTTPDataLoading {
    private let responses: [URL: StubResponse]

    init(responses: [URL: StubResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let stub = responses[url],
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: stub.statusCode,
                  httpVersion: nil,
                  headerFields: nil
              ) else {
            throw URLError(.badURL)
        }
        return (stub.data, response)
    }
}
