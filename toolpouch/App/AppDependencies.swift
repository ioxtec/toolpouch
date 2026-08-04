import SwiftData

@MainActor
struct AppDependencies {
    let currentDeviceProvider: any CurrentDeviceProviding
    let deviceStore: any DeviceStoring
    let networkCollector: any NetworkInfoCollecting
    let networkSnapshotStore: any NetworkSnapshotStoring

    static func live(modelContainer: ModelContainer) -> AppDependencies {
        AppDependencies(
            currentDeviceProvider: SystemDeviceProvider(),
            deviceStore: DeviceRepository(modelContext: modelContainer.mainContext),
            networkCollector: NetworkInfoCollector(),
            networkSnapshotStore: NetworkSnapshotRepository(
                modelContext: modelContainer.mainContext
            )
        )
    }
}
