import Charts
import SwiftUI

@MainActor
enum FunctionGraphImageExporter {
    static func copy(
        graph: FunctionGraph,
        expression: String,
        angleUnit: ScientificAngleUnit,
        theme: AppTheme
    ) -> Bool {
        let content = FunctionGraphExportView(
            graph: graph,
            expression: expression,
            angleUnit: angleUnit,
            theme: theme
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        #if os(macOS)
        guard let image = renderer.nsImage else { return false }
        SystemClipboard.copy(image)
        #elseif os(iOS)
        guard let image = renderer.uiImage else { return false }
        SystemClipboard.copy(image)
        #endif
        return true
    }
}

private struct FunctionGraphExportView: View {
    let graph: FunctionGraph
    let expression: String
    let angleUnit: ScientificAngleUnit
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Function Graphs".localizedInterfaceText)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(theme.colors.primaryText.color)

            Chart {
                if graph.yDomain.contains(0) {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(theme.colors.border.color.opacity(0.7))
                }
                if graph.xDomain.contains(0) {
                    RuleMark(x: .value("Zero", 0))
                        .foregroundStyle(theme.colors.border.color.opacity(0.7))
                }

                ForEach(graph.points) { point in
                    LineMark(
                        x: .value("x", point.x),
                        y: .value("y", point.y),
                        series: .value("Segment", point.segment)
                    )
                    .foregroundStyle(theme.colors.primaryAccent.color)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
            .chartXScale(domain: graph.xDomain)
            .chartYScale(domain: graph.yDomain)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(theme.colors.recessedSurface.color)
                    .clipped()
            }
            .chartXAxis {
                AxisMarks(position: .bottom) {
                    AxisGridLine().foregroundStyle(theme.colors.border.color.opacity(0.3))
                    AxisTick().foregroundStyle(theme.colors.secondaryText.color)
                    AxisValueLabel().foregroundStyle(theme.colors.secondaryText.color)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(theme.colors.border.color.opacity(0.3))
                    AxisTick().foregroundStyle(theme.colors.secondaryText.color)
                    AxisValueLabel().foregroundStyle(theme.colors.secondaryText.color)
                }
            }
            .clipped()
            .padding(24)
            .background(
                theme.colors.panelSurface.color,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.colors.border.color, lineWidth: 2)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("y = \(expression)")
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.colors.primaryText.color)
                    .lineLimit(2)
                Spacer()
                Text(
                    "x: \(format(graph.xDomain.lowerBound))…\(format(graph.xDomain.upperBound)) · \(angleUnit.title.localizedInterfaceText)"
                )
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(theme.colors.secondaryText.color)
            }
        }
        .padding(48)
        .frame(width: 1_200, height: 800)
        .background(theme.colors.background.color)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(1...6)))
    }
}
