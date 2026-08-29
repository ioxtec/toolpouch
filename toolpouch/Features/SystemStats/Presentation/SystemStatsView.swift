import SwiftUI

struct SystemStatsView: View {
    @Environment(\.appTheme) private var theme
    @State private var model = SystemStatsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: contentSpacing) {
                header

                if let snapshot = model.snapshot {
                    summary(snapshot)
                    resources(snapshot)
                    powerAndDevice(snapshot)
                } else {
                    ProgressView("Reading system information…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
            .padding(contentPadding)
        }
        .scrollIndicators(.never)
        .task { await model.monitor() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ScreenHeader(
                title: "System Stats",
                subtitle: "Live health and resource information",
                density: isWatch ? .compact : .regular
            )

            Button(action: model.refresh) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .toolPouchCircleSurface()
            .accessibilityLabel("Refresh system statistics")
        }
    }

    private func summary(_ snapshot: SystemStatsSnapshot) -> some View {
        LazyVGrid(columns: summaryColumns, spacing: 8) {
            SystemSummaryTile(
                title: "CPU",
                value: snapshot.cpuUsage.percentText,
                systemImage: "cpu",
                color: theme.colors.primaryAccent.color
            )
            SystemSummaryTile(
                title: "Memory",
                value: snapshot.memoryUsage.percentText,
                systemImage: "memorychip",
                color: theme.colors.secondaryAccent.color
            )
            SystemSummaryTile(
                title: "Thermal",
                value: snapshot.thermalState.title,
                systemImage: "thermometer.medium",
                color: thermalColor(snapshot.thermalState)
            )
            if let battery = snapshot.battery {
                SystemSummaryTile(
                    title: "Battery",
                    value: battery.level.percentText,
                    systemImage: "battery.75percent",
                    color: .green
                )
            }
        }
    }

    private func resources(_ snapshot: SystemStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .font(.headline)

            SystemMetricRow(
                title: "CPU",
                detail: "\(snapshot.processorCount) active cores",
                value: snapshot.cpuUsage,
                history: model.cpuHistory,
                color: theme.colors.primaryAccent.color,
                systemImage: "cpu"
            )

            Divider()

            SystemMetricRow(
                title: "Memory",
                detail: byteDetail(used: snapshot.memoryUsed, total: snapshot.memoryTotal),
                value: snapshot.memoryUsage,
                history: model.memoryHistory,
                color: theme.colors.secondaryAccent.color,
                systemImage: "memorychip"
            )

            if let storageUsage = snapshot.storageUsage {
                Divider()
                SystemMetricRow(
                    title: "Storage",
                    detail: storageDetail(snapshot),
                    value: storageUsage,
                    history: [],
                    color: .orange,
                    systemImage: "internaldrive"
                )
            }
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    private func powerAndDevice(_ snapshot: SystemStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Power & Device")
                .font(.headline)

            if let battery = snapshot.battery {
                SystemMetricRow(
                    title: "Battery",
                    detail: battery.state.title,
                    value: battery.level,
                    history: model.batteryHistory,
                    color: .green,
                    systemImage: "battery.75percent"
                )
                Divider()
            }

            SystemInfoRow(
                title: "Thermal state",
                value: snapshot.thermalState.title,
                systemImage: "thermometer.medium",
                valueColor: thermalColor(snapshot.thermalState)
            )
            Divider()
            SystemInfoRow(
                title: "Low Power Mode",
                value: snapshot.isLowPowerModeEnabled ? "On" : "Off",
                systemImage: "leaf",
                valueColor: snapshot.isLowPowerModeEnabled ? .yellow : .secondary
            )
            Divider()
            SystemInfoRow(
                title: "Uptime",
                value: Duration.seconds(snapshot.systemUptime).formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2)),
                systemImage: "clock",
                valueColor: .secondary
            )
            Divider()
            SystemInfoRow(
                title: "System",
                value: snapshot.operatingSystem,
                systemImage: ToolPlatform.current.systemImage,
                valueColor: .secondary
            )

            Text("Exact component temperatures are unavailable through public Apple APIs. Thermal state is the App Store-safe system signal.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(cardPadding)
        .toolPouchSurface(elevated: true)
    }

    private var summaryColumns: [GridItem] {
        [GridItem(.adaptive(minimum: isWatch ? 68 : 118), spacing: 8)]
    }

    private var contentPadding: CGFloat { isWatch ? 8 : ToolPouchLayout.Content.padding }
    private var contentSpacing: CGFloat { isWatch ? 10 : ToolPouchLayout.Content.spacing }
    private var cardPadding: CGFloat { isWatch ? 10 : ToolPouchLayout.Tile.padding }

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
        guard let used else { return ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory) }
        return "\(ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)) / \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory))"
    }

    private func storageDetail(_ snapshot: SystemStatsSnapshot) -> String {
        guard let available = snapshot.storageAvailable else { return "Unavailable" }
        return "\(ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file)) available"
    }
}

private struct SystemSummaryTile: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 8)
        .toolPouchSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct SystemMetricRow: View {
    let title: String
    let detail: String
    let value: Double?
    let history: [Double]
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(value.percentText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            ProgressView(value: value ?? 0)
                .tint(color)
            HStack(alignment: .bottom) {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                if history.count > 1 {
                    SystemSparkline(values: history, color: color)
                        .frame(width: 88, height: 24)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SystemInfoRow: View {
    let title: String
    let value: String
    let systemImage: String
    let valueColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Label(title, systemImage: systemImage)
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
