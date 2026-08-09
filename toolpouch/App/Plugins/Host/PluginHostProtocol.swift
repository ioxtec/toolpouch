import Foundation

/// Wire-level constants shared by every external plugin implementation.
/// Changing the shape of an existing message requires a new protocol version.
nonisolated enum PluginHostProtocol {
    static let currentVersion = 1
    static let hostVersion = ToolPluginVersion(1, 0, 0)
}

/// Language-neutral invocation passed across an external plugin runtime.
///
/// The same Codable model can be serialized for a WebAssembly memory boundary
/// or a remote service without exposing Swift ABI to plugin authors.
nonisolated struct PluginHostRequest: Codable, Equatable, Sendable {
    let protocolVersion: Int
    let id: String
    let method: PluginHostMethod
    let params: PluginExecuteParameters

    init(
        id: String,
        params: PluginExecuteParameters,
        protocolVersion: Int = PluginHostProtocol.currentVersion
    ) {
        self.protocolVersion = protocolVersion
        self.id = id
        method = .execute
        self.params = params
    }
}

nonisolated enum PluginHostMethod: String, Codable, Sendable {
    case execute
}

/// Context supplied by Toolpouch for one tool invocation.
///
/// `grantedPermissions` is the effective grant, not merely what the manifest
/// requested. Plugins must treat an omitted permission as denied.
nonisolated struct PluginExecuteParameters: Codable, Equatable, Sendable {
    let hostVersion: ToolPluginVersion
    let pluginIdentifier: ToolPluginIdentifier
    let pluginVersion: ToolPluginVersion
    let toolIdentifier: ToolDefinition.ID
    let grantedPermissions: [ToolPluginPermission]
    let input: JSONValue
}

/// Language-neutral response returned by an external plugin runtime.
nonisolated struct PluginHostResponse: Codable, Equatable, Sendable {
    let protocolVersion: Int
    let id: String
    let result: PluginHostResult?
    let error: PluginHostFailure?

    init(
        protocolVersion: Int = PluginHostProtocol.currentVersion,
        id: String,
        result: PluginHostResult? = nil,
        error: PluginHostFailure? = nil
    ) {
        self.protocolVersion = protocolVersion
        self.id = id
        self.result = result
        self.error = error
    }
}

nonisolated struct PluginHostResult: Codable, Equatable, Sendable {
    let output: JSONValue
}

/// Structured error returned by plugin code. Codes should be stable,
/// machine-readable identifiers such as `invalid_input`, while `message` is
/// safe to show to a developer or user.
nonisolated struct PluginHostFailure: Codable, Equatable, Sendable {
    let code: String
    let message: String
    let details: JSONValue?

    init(code: String, message: String, details: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}
