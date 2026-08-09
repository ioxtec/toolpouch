import Foundation
import Testing
@testable import toolpouch

struct PluginHostProtocolTests {
    @Test
    func requestRoundTripPreservesLanguageNeutralPayload() throws {
        let request = makeRequest(
            input: .object([
                "enabled": .boolean(true),
                "items": .array([.integer(7), .number(2.5), .null]),
                "name": .string("example"),
            ])
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(
            PluginHostRequest.self,
            from: data
        )

        #expect(decoded == request)
        #expect(decoded.protocolVersion == 1)
        #expect(decoded.method == .execute)
    }

    @Test
    func responseSupportsEitherResultOrStructuredFailure() throws {
        let success = PluginHostResponse(
            id: "request-1",
            result: PluginHostResult(output: .string("done"))
        )
        let failure = PluginHostResponse(
            id: "request-2",
            error: PluginHostFailure(
                code: "invalid_input",
                message: "A required field is missing.",
                details: .object(["field": .string("text")])
            )
        )

        #expect(
            try JSONDecoder().decode(
                PluginHostResponse.self,
                from: JSONEncoder().encode(success)
            ) == success
        )
        #expect(
            try JSONDecoder().decode(
                PluginHostResponse.self,
                from: JSONEncoder().encode(failure)
            ) == failure
        )
    }

    private func makeRequest(input: JSONValue) -> PluginHostRequest {
        PluginHostRequest(
            id: "request-1",
            params: PluginExecuteParameters(
                hostVersion: ToolPluginVersion(1, 0, 0),
                pluginIdentifier: ToolPluginIdentifier(
                    rawValue: "dev.example.echo"
                ),
                pluginVersion: ToolPluginVersion(1, 2, 3),
                toolIdentifier: ToolDefinition.ID(
                    rawValue: "dev.example.echo.text"
                ),
                grantedPermissions: [.network],
                input: input
            )
        )
    }
}
