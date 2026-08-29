import Foundation
import SwiftData

/// The user-facing release version and the App Store build number read from
/// the application bundle. Keeping this in one place prevents About and
/// Settings screens from formatting versions differently.
nonisolated struct AppVersionInfo: Equatable, Sendable {
    let version: String
    let build: String

    init(version: String?, build: String?) {
        self.version = Self.normalized(version)
        self.build = Self.normalized(build)
    }

    static var current: AppVersionInfo {
        AppVersionInfo(
            version: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String,
            build: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String
        )
    }

    var displayValue: String {
        "\(version) (\(build))"
    }

    private static func normalized(_ value: String?) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return "Unknown"
        }
        return value
    }
}

@MainActor
/// Owns the shared services that are created once and passed into tool destinations.
struct AppDependencies {
    let modelContainer: ModelContainer
    let toolRegistry: ToolRegistry
    let quickAccessPreferences: QuickAccessPreferences
    let themeStore: AppThemeStore
    let currentDeviceProvider: any CurrentDeviceProviding
    let deviceStore: any DeviceStoring
    let networkCollector: any NetworkInfoCollecting
    let networkSnapshotStore: any NetworkSnapshotStoring
    let wiFiScanner: any WiFiScanning
    let wiFiScanAuthorizer: any WiFiScanAuthorizing

    /// Assembles production implementations around the supplied SwiftData container.
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let toolRegistry = ToolRegistry.live()
        let platform = ToolPlatform.current

        return AppDependencies(
            modelContainer: modelContainer,
            toolRegistry: toolRegistry,
            quickAccessPreferences: QuickAccessPreferences(
                platform: platform,
                defaultToolIDs: toolRegistry.quickAccessTools(for: platform)
                    .map(\.id),
                maximumCount: toolRegistry.quickAccessMaximumCount
            ),
            themeStore: AppThemeStore(),
            currentDeviceProvider: SystemDeviceProvider(),
            deviceStore: DeviceRepository(modelContext: modelContainer.mainContext),
            networkCollector: NetworkInfoCollector(),
            networkSnapshotStore: NetworkSnapshotRepository(
                modelContext: modelContainer.mainContext
            ),
            wiFiScanner: makeWiFiScanner(),
            wiFiScanAuthorizer: makeWiFiScanAuthorizer()
        )
    }

    private static func makeWiFiScanner() -> any WiFiScanning {
        #if os(macOS)
        CoreWLANWiFiScanner()
        #else
        UnsupportedWiFiScanner()
        #endif
    }

    private static func makeWiFiScanAuthorizer() -> any WiFiScanAuthorizing {
        #if os(macOS)
        CoreLocationWiFiScanAuthorizer()
        #else
        NoOpWiFiScanAuthorizer()
        #endif
    }
}
