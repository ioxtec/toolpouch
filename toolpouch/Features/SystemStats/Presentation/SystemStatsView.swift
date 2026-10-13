import SwiftUI

struct SystemStatsView: View {
    @Environment(\.appTheme) private var theme
    @Bindable var monitor: SystemStatsMonitor
    @State private var selection = SystemStatsSection.cpu

    var body: some View {
        ScrollView {
            ToolContentLayout {
                header

                if let snapshot = monitor.snapshot {
                    SystemStatsTabBar(selection: $selection)
                    selectedPanel(snapshot)
                } else {
                    ProgressView("Reading system information…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
        }
        .scrollIndicators(.never)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ScreenHeader(
                title: "System Stats",
                subtitle: "Live health and saved history",
                density: isWatch ? .compact : .regular
            )
            Button(action: monitor.refresh) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .toolPouchCircleSurface()
            .accessibilityLabel("Refresh system statistics")
        }
    }

    @ViewBuilder
    private func selectedPanel(_ snapshot: SystemStatsSnapshot) -> some View {
        switch selection {
        case .power:
            powerPanel(snapshot)
        case .cpu:
            metricPanel(
                title: "CPU",
                value: snapshot.cpuUsage,
                detail: "\(snapshot.processorCount) active cores",
                history: monitor.cpuHistory,
                color: theme.colors.primaryAccent.color,
                systemImage: "cpu"
            )
        case .memory:
            metricPanel(
                title: "Memory",
                value: snapshot.memoryUsage,
                detail: byteDetail(used: snapshot.memoryUsed, total: snapshot.memoryTotal),
                history: monitor.memoryHistory,
                color: theme.colors.secondaryAccent.color,
                systemImage: "memorychip"
            )
        case .storage:
            storagePanel(snapshot)
        case .thermal:
            thermalPanel(snapshot)
        }
    }

    private func metricPanel(
        title: String,
        value: Double?,
        detail: String,
        history: [Double],
        color: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.large) {
            HStack {
                Label(title.localizedInterfaceText, systemImage: systemImage)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                Text(value.percentText)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
            }
            SystemProgressBar(value: value, color: color)
            HStack {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Last \(monitor.historyDuration.title.lowercased())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            historyChart(values: history, color: color)
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    private func powerPanel(_ snapshot: SystemStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.medium) {
            Text("Power & Device")
                .font(ToolPouchLayout.Typography.sectionTitle)
            if let battery = snapshot.battery {
                SystemInfoRow(
                    title: "Battery",
                    value: "\(battery.level.percentText) · \(battery.state.title.localizedInterfaceText)",
                    systemImage: "battery.75percent",
                    valueColor: .green
                )
                SystemProgressBar(value: battery.level, color: .green)
                historyChart(values: monitor.batteryHistory, color: .green)
                Divider()
            }
            SystemInfoRow(
                title: "Low Power Mode",
                value: (snapshot.isLowPowerModeEnabled ? "On" : "Off").localizedInterfaceText,
                systemImage: "leaf",
                valueColor: snapshot.isLowPowerModeEnabled ? .yellow : .secondary
            )
            Divider()
            SystemInfoRow(
                title: "System",
                value: snapshot.operatingSystem,
                systemImage: ToolPlatform.current.systemImage,
                valueColor: .secondary
            )
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    private func storagePanel(_ snapshot: SystemStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.large) {
            Text("Storage")
                .font(ToolPouchLayout.Typography.sectionTitle)
            if snapshot.disks.isEmpty {
                if let usage = snapshot.storageUsage {
                    diskFallback(snapshot, usage: usage)
                } else {
                    ContentUnavailableView("Storage unavailable", systemImage: "internaldrive")
                }
            } else {
                ForEach(Array(snapshot.disks.enumerated()), id: \.element.id) { index, disk in
                    if index > 0 { Divider() }
                    diskView(disk)
                }
            }
            if monitor.storageHistory.count > 1 {
                Divider()
                Text("Usage history · Last \(monitor.historyDuration.title.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                historyChart(values: monitor.storageHistory, color: .orange)
            }
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    private func diskView(_ disk: SystemDiskSnapshot) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
            HStack {
                Label(disk.name, systemImage: "internaldrive")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(disk.usage.percentText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            SystemProgressBar(value: disk.usage, color: .orange)
            HStack {
                Text("\(bytes(disk.available)) available")
                Spacer()
                Text(diskMetadata(disk))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func diskFallback(_ snapshot: SystemStatsSnapshot, usage: Double) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
            HStack {
                Label("Device storage", systemImage: "internaldrive")
                Spacer()
                Text(usage.percentText)
            }
            .font(.subheadline.weight(.semibold))
            SystemProgressBar(value: usage, color: .orange)
            Text(storageDetail(snapshot))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func thermalPanel(_ snapshot: SystemStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.medium) {
            HStack {
                Label("Thermal state", systemImage: "thermometer.medium")
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                Text(snapshot.thermalState.title.localizedInterfaceText)
                    .font(.headline)
                    .foregroundStyle(thermalColor(snapshot.thermalState))
            }
            Text(snapshot.thermalState.explanation.localizedInterfaceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            SystemInfoRow(
                title: "CPU temperature",
                value: "Not available",
                systemImage: "cpu",
                valueColor: .secondary
            )
            Divider()
            SystemInfoRow(
                title: "Battery temperature",
                value: "Not available",
                systemImage: "battery.75percent",
                valueColor: .secondary
            )
            Text("Apple does not expose exact component temperatures through public APIs. Using private sensor access would conflict with App Store distribution, so ToolPouch reports the system thermal state instead.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    @ViewBuilder
    private func historyChart(values: [Double], color: Color) -> some View {
        if values.count > 1 {
            SystemSparkline(values: values, color: color)
                .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
        } else {
            Text("Collecting history…")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 38, alignment: .center)
        }
    }

    private var cardPadding: CGFloat { isWatch ? 8 : ToolPouchLayout.Spacing.large }

    private var isWatch: Bool {
        #if os(watchOS)
        true
        #else
        false
        #endif
    }

    private func thermalColor(_ state: SystemThermalState) -> Color {
        switch state {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        case .unknown: .secondary
        }
    }

    private func byteDetail(used: UInt64?, total: UInt64) -> String {
        guard let used else { return bytes(total) }
        return "\(bytes(used)) / \(bytes(total))"
    }

    private func storageDetail(_ snapshot: SystemStatsSnapshot) -> String {
        guard let available = snapshot.storageAvailable else { return "Unavailable" }
        return "\(bytes(available)) available"
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }

    private func diskMetadata(_ disk: SystemDiskSnapshot) -> String {
        let location = disk.isInternal == true ? "Internal" : (disk.isRemovable == true ? "External" : nil)
        return [disk.format, location, bytes(disk.total)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

private enum SystemStatsSection: String, CaseIterable, Identifiable {
    case power
    case cpu
    case memory
    case storage
    case thermal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .power: "Power"
        case .cpu: "CPU"
        case .memory: "Memory"
        case .storage: "Storage"
        case .thermal: "Thermal"
        }
    }

    var systemImage: String {
        switch self {
        case .power: "bolt"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .thermal: "thermometer.medium"
        }
    }
}

private struct SystemStatsTabBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var selection: SystemStatsSection

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: ToolPouchLayout.Spacing.small) {
                ForEach(SystemStatsSection.allCases) { section in
                    Button { selection = section } label: {
                        VStack(spacing: 3) {
                            Image(systemName: section.systemImage)
                                .toolPouchIcon(.small, weight: .medium)
                            Text(section.title.localizedInterfaceText)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            selection == section
                                ? theme.colors.primaryAccent.color
                                : Color.secondary
                        )
                        .frame(minWidth: 58, minHeight: 46)
                        .padding(.horizontal, 2)
                        .contentShape(.rect)
                        .background(
                            selection == section
                                ? theme.colors.accentButtonBackground.color
                                : theme.colors.recessedSurface.color,
                            in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(section.title.localizedInterfaceText)
                    .accessibilityAddTraits(selection == section ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.never)
    }
}

private struct SystemProgressBar: View {
    let value: Double?
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.18))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(value ?? 0, 0), 1))
            }
        }
        .frame(height: 4)
        .accessibilityValue(value.percentText)
    }
}

private struct SystemInfoRow: View {
    let title: String
    let value: String
    let systemImage: String
    let valueColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Label(title.localizedInterfaceText, systemImage: systemImage)
                .font(.subheadline)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension Optional where Wrapped == Double {
    var percentText: String {
        guard let value = self else { return "—" }
        return value.formatted(.percent.precision(.fractionLength(0)))
    }
}

private extension Double {
    var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}

private extension SystemThermalState {
    var explanation: String {
        switch self {
        case .nominal:
            "The system is operating normally and is not reducing performance because of heat."
        case .fair:
            "The device is warmer than usual and may begin reducing background work."
        case .serious:
            "Thermal pressure is high. The system may reduce performance to cool down."
        case .critical:
            "Thermal pressure is critical. Stop demanding work and allow the device to cool."
        case .unknown:
            "The operating system did not provide a thermal-pressure reading."
        }
    }
}
