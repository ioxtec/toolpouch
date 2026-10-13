import Foundation
import Observation

/// One monitor is shared by every System Stats screen. It keeps collecting
/// while the menu-bar app is running, so reopening the tool reuses its history
/// instead of starting a new chart. iOS and watchOS may suspend this task when
/// the app is backgrounded; already collected samples remain available.
@MainActor
@Observable
final class SystemStatsMonitor {
    private(set) var snapshot: SystemStatsSnapshot?
    private(set) var samples: [SystemStatsSample]

    @ObservationIgnored private let collector: any SystemStatsCollecting
    @ObservationIgnored private let historyStore: SystemStatsHistoryStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let sampleInterval: Duration
    @ObservationIgnored private var monitoringTask: Task<Void, Never>?
    @ObservationIgnored private var lastCompactionDate = Date.distantPast

    init(
        collector: any SystemStatsCollecting = SystemStatsCollector(),
        historyStore: SystemStatsHistoryStore = SystemStatsHistoryStore(),
        defaults: UserDefaults = .standard,
        sampleInterval: Duration = .seconds(10)
    ) {
        self.collector = collector
        self.historyStore = historyStore
        self.defaults = defaults
        self.sampleInterval = sampleInterval
        samples = historyStore.load()
        trimHistory(referenceDate: .now, persist: true)
    }

    deinit {
        monitoringTask?.cancel()
    }

    func start() {
        guard monitoringTask == nil else { return }
        refresh()
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    guard let interval = self?.sampleInterval else { return }
                    try await Task.sleep(for: interval)
                    self?.refresh()
                } catch {
                    return
                }
            }
        }
    }

    func refresh() {
        let current = collector.collect()
        snapshot = current
        let sample = SystemStatsSample(snapshot: current)
        samples.append(sample)
        historyStore.append(sample)
        trimHistory(referenceDate: current.capturedAt, persist: false)
    }

    func applyHistoryPreference() {
        trimHistory(referenceDate: .now, persist: true)
    }

    var historyDuration: SystemStatsHistoryDuration {
        SystemStatsHistoryDuration(
            rawValue: defaults.integer(forKey: AppPreferenceKey.systemStatsHistoryDuration)
        ) ?? .defaultValue
    }

    var cpuHistory: [Double] { samples.compactMap(\.cpuUsage) }
    var memoryHistory: [Double] { samples.compactMap(\.memoryUsage) }
    var storageHistory: [Double] { samples.compactMap(\.storageUsage) }
    var batteryHistory: [Double] { samples.compactMap(\.batteryLevel) }

    private func trimHistory(referenceDate: Date, persist: Bool) {
        let cutoff = referenceDate.addingTimeInterval(-TimeInterval(historyDuration.rawValue))
        let previousCount = samples.count
        samples.removeAll { $0.capturedAt < cutoff }
        if persist || (samples.count != previousCount && referenceDate.timeIntervalSince(lastCompactionDate) >= 300) {
            historyStore.replace(with: samples)
            lastCompactionDate = referenceDate
        }
    }
}
