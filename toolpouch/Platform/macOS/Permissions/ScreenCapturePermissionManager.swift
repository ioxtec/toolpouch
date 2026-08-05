#if os(macOS)
import AppKit
import CoreGraphics
import Observation

@MainActor
@Observable
final class ScreenCapturePermissionManager {
    static let shared = ScreenCapturePermissionManager()

    private(set) var isGranted = false

    private init() {
        refresh()
    }

    /// Refreshes the status reported by macOS without displaying a system prompt.
    func refresh() {
        isGranted = CGPreflightScreenCaptureAccess()
    }

    /// Displays the system request only after an explicit user action.
    func requestAccess() {
        isGranted = CGRequestScreenCaptureAccess()
    }

    func openSystemSettings() {
        let modernURL = URL(
            string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        )
        let legacyURL = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )

        if let modernURL, NSWorkspace.shared.open(modernURL) {
            return
        }
        if let legacyURL {
            NSWorkspace.shared.open(legacyURL)
        }
    }
}
#endif
