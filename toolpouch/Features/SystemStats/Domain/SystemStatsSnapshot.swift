import Foundation

nonisolated struct SystemStatsSnapshot: Sendable, Equatable {
    let capturedAt: Date
    let cpuUsage: Double?
    let memoryUsed: UInt64?
    let memoryTotal: UInt64
    let storageAvailable: UInt64?
    let storageTotal: UInt64?
    let battery: SystemBatterySnapshot?
    let thermalState: SystemThermalState
    let isLowPowerModeEnabled: Bool
    let systemUptime: TimeInterval
    let processorCount: Int
    let operatingSystem: String

    var memoryUsage: Double? {
        guard let memoryUsed, memoryTotal > 0 else { return nil }
        return min(max(Double(memoryUsed) / Double(memoryTotal), 0), 1)
    }

    var storageUsage: Double? {
        guard let storageAvailable, let storageTotal, storageTotal > 0 else { return nil }
        return min(max(1 - Double(storageAvailable) / Double(storageTotal), 0), 1)
    }
}

nonisolated struct SystemBatterySnapshot: Sendable, Equatable {
    let level: Double
    let state: SystemBatteryState

    init(level: Double, state: SystemBatteryState) {
        self.level = min(max(level, 0), 1)
        self.state = state
    }
}

nonisolated enum SystemBatteryState: String, Sendable {
    case charging
    case full
    case unplugged
    case unknown

    var title: String {
        switch self {
        case .charging: "Charging"
        case .full: "Fully charged"
        case .unplugged: "On battery"
        case .unknown: "Unknown"
        }
    }
}

nonisolated enum SystemThermalState: String, Sendable {
    case nominal
    case fair
    case serious
    case critical
    case unknown

    var title: String {
        switch self {
        case .nominal: "Normal"
        case .fair: "Elevated"
        case .serious: "High"
        case .critical: "Critical"
        case .unknown: "Unavailable"
        }
    }
}
