import Foundation

/// Decides which capabilities a device exposes, and therefore which tools
/// are available. Centralizes the platform checks that used to be scattered
/// across `#if os(...)` blocks in the registry and project configuration.
nonisolated protocol CapabilityResolving: Sendable {
    /// The platform the current device is running.
    var platform: ToolPlatform { get }

    /// Whether the device exposes the given capability.
    func hasCapability(_ capability: ToolCapability) -> Bool

    /// Whether a tool that requires the given capabilities is available.
    func supports(requiredCapabilities: Set<ToolCapability>) -> Bool
}

extension CapabilityResolving {
    nonisolated func supports(requiredCapabilities: Set<ToolCapability>) -> Bool {
        requiredCapabilities.allSatisfy(hasCapability)
    }
}
