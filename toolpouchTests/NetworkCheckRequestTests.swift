import Testing
@testable import toolpouch

struct NetworkCheckRequestTests {
    @Test
    func normalizesPlainHostsAndURLs() throws {
        #expect(
            try NetworkCheckRequest(host: " example.com ", port: 443).host
                == "example.com"
        )
        #expect(
            try NetworkCheckRequest(
                host: "https://www.example.com/path?q=value",
                port: 443
            ).host == "www.example.com"
        )
        #expect(
            try NetworkCheckRequest(host: "[2001:db8::1]", port: 22).host
                == "2001:db8::1"
        )
    }

    @Test(arguments: [0, 65_536, -1])
    func rejectsInvalidPorts(_ port: Int) {
        #expect(throws: NetworkCheckError.invalidPort) {
            try NetworkCheckRequest(host: "example.com", port: port)
        }
    }

    @Test(arguments: ["", "   ", "not a host"])
    func rejectsInvalidHosts(_ host: String) {
        #expect(throws: NetworkCheckError.invalidHost) {
            try NetworkCheckRequest(host: host, port: 443)
        }
    }
}
