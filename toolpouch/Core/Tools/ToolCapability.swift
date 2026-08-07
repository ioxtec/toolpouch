import Foundation

/// A discrete hardware, OS, or permission capability that a tool may require.
/// Tools declare the capabilities they need; the device reports which it has.
nonisolated enum ToolCapability: String, Codable, CaseIterable, Sendable {
    /// A screen that can be captured (macOS only).
    case screenCapture
    /// Access to the system clipboard.
    case clipboard
    /// Access to Wi-Fi scanning (CoreWLAN on macOS).
    case wiFiScanning
    /// Access to the user's SSH key folder.
    case sshKeys
    /// A network connection is available.
    case network
    /// The device can run the Rust engine (all supported platforms).
    case rustEngine
    /// The device has a screen large enough for a grid layout.
    case gridLayout
}

extension ToolCapability {
    /// The platform that is required for this capability, if any.
    nonisolated var requiredPlatform: ToolPlatform? {
        switch self {
        case .screenCapture, .clipboard, .wiFiScanning, .sshKeys:
            .macOS
        case .network, .rustEngine, .gridLayout:
            nil
        }
    }
}
