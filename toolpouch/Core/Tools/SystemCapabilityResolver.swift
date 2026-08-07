import Foundation

/// Production capability resolver that maps the current platform to the
/// capabilities it exposes. This is the single source of truth for tool
/// availability, replacing the `#if os(...)` checks in the registry.
nonisolated struct SystemCapabilityResolver: CapabilityResolving {
    let platform: ToolPlatform

    init(platform: ToolPlatform = .current) {
        self.platform = platform
    }

    nonisolated func hasCapability(_ capability: ToolCapability) -> Bool {
        // A capability that is tied to a specific platform is only available
        // when the current platform matches.
        if let requiredPlatform = capability.requiredPlatform,
           requiredPlatform != platform {
            return false
        }

        switch capability {
        case .screenCapture, .clipboard, .wiFiScanning, .sshKeys:
            // These are macOS-only and already gated by requiredPlatform.
            return true
        case .network:
            // Every supported platform can reach the network.
            return true
        case .rustEngine:
            // The Rust engine is embedded on every supported platform.
            return true
        case .gridLayout:
            // watchOS uses a compact list instead of a grid.
            return platform != .watchOS
        }
    }
}
