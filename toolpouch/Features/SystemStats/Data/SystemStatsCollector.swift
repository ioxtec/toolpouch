import Darwin
import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import IOKit.ps
#endif

/// Collects only documented or public system information so the tool remains
/// suitable for App Store distribution. Apple does not provide a public API
/// for exact CPU/GPU temperatures, so thermal pressure is reported instead.
final class SystemStatsCollector: SystemStatsCollecting {
    private var previousCPUTicks: CPUTicks?

    func collect() -> SystemStatsSnapshot {
        let processInfo = ProcessInfo.processInfo
        let storage = storageCapacity()

        return SystemStatsSnapshot(
            capturedAt: .now,
            cpuUsage: cpuUsage(),
            memoryUsed: memoryUsed(total: processInfo.physicalMemory),
            memoryTotal: processInfo.physicalMemory,
            storageAvailable: storage?.available,
            storageTotal: storage?.total,
            battery: batterySnapshot(),
            thermalState: SystemThermalState(processInfo.thermalState),
            isLowPowerModeEnabled: processInfo.isLowPowerModeEnabled,
            systemUptime: processInfo.systemUptime,
            processorCount: processInfo.activeProcessorCount,
            operatingSystem: processInfo.operatingSystemVersionString
        )
    }

    private func cpuUsage() -> Double? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let ticks = CPUTicks(info: info)
        defer { previousCPUTicks = ticks }
        guard let previousCPUTicks else {
            return ticks.usage(since: .zero)
        }
        return ticks.usage(since: previousCPUTicks)
    }

    private func memoryUsed(total: UInt64) -> UInt64? {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }
        // macOS presents file-backed pages as "Cached Files", not as memory
        // used by apps or the system. They can be reclaimed on demand, so count
        // them with free and speculative pages when deriving user-facing usage.
        return SystemMemoryUsageCalculator.usedBytes(
            total: total,
            pageSize: UInt64(pageSize),
            freePages: UInt64(statistics.free_count),
            speculativePages: UInt64(statistics.speculative_count),
            fileBackedPages: UInt64(statistics.external_page_count)
        )
    }

    private func storageCapacity() -> (available: UInt64, total: UInt64)? {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
        let available = attributes[.systemFreeSize] as? NSNumber,
        let total = attributes[.systemSize] as? NSNumber else {
            return nil
        }
        return (available.uint64Value, total.uint64Value)
    }

    private func batterySnapshot() -> SystemBatterySnapshot? {
        #if os(iOS)
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        guard device.batteryLevel >= 0 else { return nil }
        return SystemBatterySnapshot(
            level: Double(device.batteryLevel),
            state: SystemBatteryState(device.batteryState)
        )
        #elseif os(watchOS)
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        guard device.batteryLevel >= 0 else { return nil }
        return SystemBatterySnapshot(
            level: Double(device.batteryLevel),
            state: SystemBatteryState(device.batteryState)
        )
        #elseif os(macOS)
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any],
                  let current = description[kIOPSCurrentCapacityKey] as? NSNumber,
                  let maximum = description[kIOPSMaxCapacityKey] as? NSNumber,
                  maximum.doubleValue > 0 else { continue }

            let state = description[kIOPSIsChargingKey] as? Bool == true
                ? SystemBatteryState.charging
                : SystemBatteryState.unplugged
            return SystemBatterySnapshot(
                level: current.doubleValue / maximum.doubleValue,
                state: current.doubleValue >= maximum.doubleValue ? .full : state
            )
        }
        return nil
        #else
        return nil
        #endif
    }
}

/// Keeps the definition of "used" memory explicit and independently testable.
/// This mirrors Activity Monitor's distinction between used RAM and reusable
/// file cache instead of treating every occupied physical page as unavailable.
nonisolated enum SystemMemoryUsageCalculator {
    static func usedBytes(
        total: UInt64,
        pageSize: UInt64,
        freePages: UInt64,
        speculativePages: UInt64,
        fileBackedPages: UInt64
    ) -> UInt64 {
        let reclaimablePages = freePages
            + speculativePages
            + fileBackedPages
        let reclaimableBytes = reclaimablePages.multipliedReportingOverflow(by: pageSize)
        guard !reclaimableBytes.overflow else { return 0 }
        return total - min(reclaimableBytes.partialValue, total)
    }
}

private struct CPUTicks {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64

    static let zero = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)

    init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    init(info: host_cpu_load_info) {
        user = UInt64(info.cpu_ticks.0)
        system = UInt64(info.cpu_ticks.1)
        idle = UInt64(info.cpu_ticks.2)
        nice = UInt64(info.cpu_ticks.3)
    }

    func usage(since previous: CPUTicks) -> Double? {
        let busy = user &- previous.user + system &- previous.system + nice &- previous.nice
        let idle = idle &- previous.idle
        let total = busy + idle
        guard total > 0 else { return nil }
        return min(max(Double(busy) / Double(total), 0), 1)
    }
}

private extension SystemThermalState {
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .unknown
        }
    }
}

#if os(iOS)
private extension SystemBatteryState {
    init(_ state: UIDevice.BatteryState) {
        switch state {
        case .charging: self = .charging
        case .full: self = .full
        case .unplugged: self = .unplugged
        case .unknown: self = .unknown
        @unknown default: self = .unknown
        }
    }
}
#elseif os(watchOS)
private extension SystemBatteryState {
    init(_ state: WKInterfaceDeviceBatteryState) {
        switch state {
        case .charging: self = .charging
        case .full: self = .full
        case .unplugged: self = .unplugged
        case .unknown: self = .unknown
        @unknown default: self = .unknown
        }
    }
}
#endif
