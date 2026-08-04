import Foundation
import Observation

@MainActor
@Observable
final class NetworkInfoViewModel {
    private(set) var selectedSnapshot: NetworkInfoSnapshot?
    private(set) var recentSnapshots: [NetworkInfoSnapshot] = []
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?

    private let currentDeviceProvider: any CurrentDeviceProviding
    private let deviceStore: any DeviceStoring
    private let collector: any NetworkInfoCollecting
    private let snapshotStore: any NetworkSnapshotStoring

    init(dependencies: AppDependencies) {
        currentDeviceProvider = dependencies.currentDeviceProvider
        deviceStore = dependencies.deviceStore
        collector = dependencies.networkCollector
        snapshotStore = dependencies.networkSnapshotStore
    }

    var latestDeviceSnapshots: [NetworkInfoSnapshot] {
        var deviceIDs = Set<UUID>()
        return recentSnapshots.filter { snapshot in
            deviceIDs.insert(snapshot.deviceID).inserted
        }
    }

    func load() {
        do {
            recentSnapshots = try snapshotStore.fetchLatest(limit: 50)
            selectedSnapshot = recentSnapshots.first
            errorMessage = nil
        } catch {
            errorMessage = "Saved network information could not be loaded."
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        let device = currentDeviceProvider.currentDevice()
        let snapshot = await collector.collect(for: device)

        do {
            try deviceStore.save(device)
            try snapshotStore.save(snapshot)
            recentSnapshots = try snapshotStore.fetchLatest(limit: 50)
            selectedSnapshot = snapshot
        } catch {
            selectedSnapshot = snapshot
            errorMessage = "Network information was refreshed but could not be saved."
        }
    }

    func select(_ snapshot: NetworkInfoSnapshot) {
        selectedSnapshot = snapshot
    }
}
