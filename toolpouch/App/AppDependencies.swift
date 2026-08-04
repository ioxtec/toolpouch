import SwiftData

@MainActor
struct AppDependencies {
    let toolRegistry: ToolRegistry
    let currentDeviceProvider: any CurrentDeviceProviding
    let deviceStore: any DeviceStoring
    let networkCollector: any NetworkInfoCollecting
    let networkSnapshotStore: any NetworkSnapshotStoring
    let wiFiScanner: any WiFiScanning
    let wiFiScanAuthorizer: any WiFiScanAuthorizing

    static func live(modelContainer: ModelContainer) -> AppDependencies {
        AppDependencies(
            toolRegistry: .live(),
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
