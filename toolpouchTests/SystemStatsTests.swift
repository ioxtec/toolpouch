import Foundation
import Testing
@testable import toolpouch

@MainActor
struct SystemStatsTests {
    @Test
    func liveCollectorReturnsSensibleCoreValues() {
        let snapshot = SystemStatsCollector().collect()

        #expect(snapshot.memoryTotal > 0)
        #expect(snapshot.processorCount > 0)
        #expect(snapshot.systemUptime > 0)
        #expect(snapshot.cpuUsage.map { (0...1).contains($0) } ?? false)
    }

    @Test
    func memoryUsageExcludesReusableFileCache() {
        let gibibyte = UInt64(1_073_741_824)
        let used = SystemMemoryUsageCalculator.usedBytes(
            total: 24 * gibibyte,
            pageSize: 16_384,
            freePages: 4_096,
            speculativePages: 2_048,
            fileBackedPages: 190_464
        )

        #expect(used == 21 * gibibyte)
    }

    @Test
    func derivedUsageValuesAreClamped() {
        let snapshot = SystemStatsSnapshot(
            capturedAt: .now,
            cpuUsage: 0.4,
            memoryUsed: 12,
            memoryTotal: 10,
            storageAvailable: 30,
            storageTotal: 100,
            battery: SystemBatterySnapshot(level: 1.2, state: .full),
            thermalState: .nominal,
            isLowPowerModeEnabled: false,
            systemUptime: 60,
            processorCount: 8,
            operatingSystem: "Test OS"
        )

        #expect(snapshot.memoryUsage == 1)
        #expect(snapshot.storageUsage == 0.7)
        #expect(snapshot.battery?.level == 1)
    }

    @Test
    func historyKeepsOnlyNewestSamples() {
        let collector = SequenceSystemStatsCollector(cpuValues: [0.1, 0.2, 0.3])
        let model = SystemStatsViewModel(collector: collector, historyLimit: 2)

        model.refresh()
        model.refresh()
        model.refresh()

        #expect(model.cpuHistory == [0.2, 0.3])
    }
}

@MainActor
private final class SequenceSystemStatsCollector: SystemStatsCollecting {
    private var cpuValues: [Double]

    init(cpuValues: [Double]) {
        self.cpuValues = cpuValues
    }

    func collect() -> SystemStatsSnapshot {
        SystemStatsSnapshot(
            capturedAt: .now,
            cpuUsage: cpuValues.removeFirst(),
            memoryUsed: 1,
            memoryTotal: 2,
            storageAvailable: 1,
            storageTotal: 2,
            battery: nil,
            thermalState: .nominal,
            isLowPowerModeEnabled: false,
            systemUptime: 60,
            processorCount: 1,
            operatingSystem: "Test OS"
        )
    }
}
