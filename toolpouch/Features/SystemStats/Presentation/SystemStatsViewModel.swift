import Foundation
import Observation

@MainActor
@Observable
final class SystemStatsViewModel {
    private(set) var snapshot: SystemStatsSnapshot?
    private(set) var cpuHistory: [Double] = []
    private(set) var memoryHistory: [Double] = []
    private(set) var batteryHistory: [Double] = []

    private let collector: any SystemStatsCollecting
    private let historyLimit: Int

    init(
        collector: any SystemStatsCollecting = SystemStatsCollector(),
        historyLimit: Int = 60
    ) {
        self.collector = collector
        self.historyLimit = max(historyLimit, 1)
    }

    func refresh() {
        let snapshot = collector.collect()
        self.snapshot = snapshot
        append(snapshot.cpuUsage, to: &cpuHistory)
        append(snapshot.memoryUsage, to: &memoryHistory)
        append(snapshot.battery?.level, to: &batteryHistory)
    }

    func monitor() async {
        refresh()
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            refresh()
        }
    }

    private func append(_ value: Double?, to history: inout [Double]) {
        guard let value else { return }
        history.append(value)
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}
