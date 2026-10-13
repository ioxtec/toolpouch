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
    let processorCount: Int
    let operatingSystem: String
    let disks: [SystemDiskSnapshot]

    init(
        capturedAt: Date,
        cpuUsage: Double?,
        memoryUsed: UInt64?,
        memoryTotal: UInt64,
        storageAvailable: UInt64?,
        storageTotal: UInt64?,
        battery: SystemBatterySnapshot?,
        thermalState: SystemThermalState,
        isLowPowerModeEnabled: Bool,
        processorCount: Int,
        operatingSystem: String,
        disks: [SystemDiskSnapshot] = []
    ) {
        self.capturedAt = capturedAt
        self.cpuUsage = cpuUsage
        self.memoryUsed = memoryUsed
        self.memoryTotal = memoryTotal
        self.storageAvailable = storageAvailable
        self.storageTotal = storageTotal
        self.battery = battery
        self.thermalState = thermalState
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.processorCount = processorCount
        self.operatingSystem = operatingSystem
        self.disks = disks
    }

    var memoryUsage: Double? {
        guard let memoryUsed, memoryTotal > 0 else { return nil }
        return min(max(Double(memoryUsed) / Double(memoryTotal), 0), 1)
    }

    var storageUsage: Double? {
        guard let storageAvailable, let storageTotal, storageTotal > 0 else { return nil }
        return min(max(1 - Double(storageAvailable) / Double(storageTotal), 0), 1)
    }
}

nonisolated struct SystemDiskSnapshot: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let available: UInt64
    let total: UInt64
    let format: String?
    let isInternal: Bool?
    let isRemovable: Bool?

    var usage: Double? {
        guard total > 0 else { return nil }
        return min(max(1 - Double(available) / Double(total), 0), 1)
    }
}

/// One compact point retained for history charts. The complete live snapshot
/// stays in memory; only values useful for charts are written to preferences.
nonisolated struct SystemStatsSample: Codable, Sendable, Equatable, Identifiable {
    let capturedAt: Date
    let cpuUsage: Double?
    let memoryUsage: Double?
    let storageUsage: Double?
    let batteryLevel: Double?

    var id: Date { capturedAt }

    init(snapshot: SystemStatsSnapshot) {
        capturedAt = snapshot.capturedAt
        cpuUsage = snapshot.cpuUsage
        memoryUsage = snapshot.memoryUsage
        storageUsage = snapshot.storageUsage
        batteryLevel = snapshot.battery?.level
    }
}

nonisolated enum SystemStatsHistoryDuration: Int, CaseIterable, Identifiable, Sendable {
    case oneHour = 3_600
    case sixHours = 21_600
    case twelveHours = 43_200
    case oneDay = 86_400

    static let defaultValue = SystemStatsHistoryDuration.oneHour
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .oneHour: "1 hour"
        case .sixHours: "6 hours"
        case .twelveHours: "12 hours"
        case .oneDay: "24 hours"
        }
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
