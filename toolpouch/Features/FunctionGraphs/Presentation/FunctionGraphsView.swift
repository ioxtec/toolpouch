import Charts
import Foundation
import SwiftUI

struct FunctionGraphsView: View {
    private let sampler: any FunctionGraphSampling

    @Environment(\.appTheme) private var theme
    @Environment(\.openToolInWindow) private var openToolInWindow
    @Environment(\.toolPouchPresentationMode) private var presentationMode
    @AppStorage(AppPreferenceKey.functionGraphExpression)
    private var expression = "sin(x)"
    @AppStorage(AppPreferenceKey.functionGraphLowerBound)
    private var lowerBound = "-10"
    @AppStorage(AppPreferenceKey.functionGraphUpperBound)
    private var upperBound = "10"
    @AppStorage(AppPreferenceKey.functionGraphAngleUnit)
    private var angleUnit = ScientificAngleUnit.radians
    @State private var graph: FunctionGraph?
    @State private var errorMessage: String?
    @State private var selectedPoint: FunctionGraphPoint?
    @State private var imageCopied = false

    init(sampler: any FunctionGraphSampling) {
        self.sampler = sampler
    }

    @ViewBuilder
    var body: some View {
        if presentationMode == .expandedWindow {
            GeometryReader { geometry in
                content(
                    graphHeight: expandedGraphHeight(
                        for: geometry.size.height
                    )
                )
            }
        } else {
            content(graphHeight: nil)
        }
    }

    private func content(graphHeight: CGFloat?) -> some View {
        ScrollView {
            ToolContentLayout {
                ScreenHeader(
                    title: "Function Graphs",
                    subtitle: "Plot mathematical expressions and explore their ranges."
                )
                graphCard(graphHeight: graphHeight)
                syntaxHint
            }
        }
        .scrollIndicators(.never)
        .task { updateGraph() }
    }

    private func graphCard(graphHeight: CGFloat?) -> some View {
        ToolSectionCard {
            topControls
            expressionField
            rangeControls
            Divider()
            graphContent(height: graphHeight)
        }
    }

    private var topControls: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            ToolPouchSegmentedControl(
                ScientificAngleUnit.allCases,
                selection: $angleUnit,
                title: \.title
            )
            .onChange(of: angleUnit) { updateGraph() }

            Menu {
                ForEach(FunctionGraphExample.allCases) { example in
                    Button(example.title.localizedInterfaceText) {
                        expression = example.expression
                        lowerBound = example.lowerBound
                        upperBound = example.upperBound
                        updateGraph()
                    }
                }
            } label: {
                Label("Examples", systemImage: "sparkles")
            }
            .toolPouchSecondaryAction()
        }
    }

    private var expressionField: some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
            ToolFieldLabel(
                "Function",
                systemImage: "function",
                helpText: "Plot mathematical expressions and explore their ranges."
            )
            HStack(spacing: ToolPouchLayout.Spacing.medium) {
                Text("y =")
                    .font(ToolPouchLayout.Typography.value)
                    .foregroundStyle(theme.colors.secondaryText.color)
                TextField("Enter a function of x", text: $expression)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit(updateGraph)
                    .accessibilityLabel("Function expression")
                Button(action: updateGraph) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Draw graph")
                .accessibilityLabel("Draw graph")
            }
            .toolPouchControlSurface()
        }
    }

    private var rangeControls: some View {
        HStack(spacing: ToolPouchLayout.Spacing.large) {
            rangeField(title: "Minimum x", value: $lowerBound)
            rangeField(title: "Maximum x", value: $upperBound)
        }
    }

    private func rangeField(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
            ToolFieldLabel(title)
            TextField(title.localizedInterfaceText, text: value)
                .textFieldStyle(.plain)
                .font(ToolPouchLayout.Typography.value)
                .onSubmit(updateGraph)
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .toolPouchControlSurface()
        }
    }

    @ViewBuilder
    private func graphContent(height: CGFloat?) -> some View {
        if let graph {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.medium) {
                graphActions(for: graph)
                Chart {
                    if graph.yDomain.contains(0) {
                        RuleMark(y: .value("Zero", 0))
                            .foregroundStyle(theme.colors.border.color.opacity(0.55))
                    }
                    if graph.xDomain.contains(0) {
                        RuleMark(x: .value("Zero", 0))
                            .foregroundStyle(theme.colors.border.color.opacity(0.55))
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
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                    }

                    if let selectedPoint {
                        RuleMark(x: .value("Selected x", selectedPoint.x))
                            .foregroundStyle(theme.colors.secondaryAccent.color.opacity(0.72))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        PointMark(
                            x: .value("Selected x", selectedPoint.x),
                            y: .value("Selected y", selectedPoint.y)
                        )
                        .foregroundStyle(theme.colors.secondaryAccent.color)
                        .symbolSize(38)
                    }
                }
                .chartXScale(domain: graph.xDomain)
                .chartYScale(domain: graph.yDomain)
                .chartPlotStyle { plotArea in
                    plotArea.clipped()
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisGridLine().foregroundStyle(theme.colors.border.color.opacity(0.25))
                        AxisTick().foregroundStyle(theme.colors.secondaryText.color)
                        AxisValueLabel().foregroundStyle(theme.colors.secondaryText.color)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(theme.colors.border.color.opacity(0.25))
                        AxisTick().foregroundStyle(theme.colors.secondaryText.color)
                        AxisValueLabel().foregroundStyle(theme.colors.secondaryText.color)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(.rect)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else {
                                            selectedPoint = nil
                                            return
                                        }
                                        let frame = geometry[plotFrame]
                                        selectPoint(
                                            at: value.location.x - frame.minX,
                                            proxy: proxy
                                        )
                                    }
                                    .onEnded { _ in selectedPoint = nil }
                            )
                    }
                }
                .modifier(FunctionGraphHeightModifier(height: height))
                .clipped()
                .padding(ToolPouchLayout.Spacing.medium)
                .toolPouchSurface(
                    interactive: true,
                    cornerRadius: ToolPouchLayout.Radius.control
                )

                if let selectedPoint {
                    Text("x = \(format(selectedPoint.x))   y = \(format(selectedPoint.y))")
                        .font(ToolPouchLayout.Typography.compactSupporting.monospacedDigit())
                        .foregroundStyle(theme.colors.secondaryText.color)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        } else if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(ToolPouchLayout.Typography.supporting)
                .foregroundStyle(theme.colors.danger.color)
                .frame(maxWidth: .infinity, minHeight: 180)
                .padding()
                .toolPouchSurface(
                    interactive: true,
                    cornerRadius: ToolPouchLayout.Radius.control
                )
        }
    }

    private func graphActions(for graph: FunctionGraph) -> some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            Text("Graph".localizedInterfaceText)
                .font(ToolPouchLayout.Typography.sectionTitle)
            Spacer()

            Button {
                copyGraphImage(graph)
            } label: {
                Image(systemName: imageCopied ? "checkmark" : "photo.on.rectangle.angled")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .toolPouchCircleSurface()
            .help(
                (imageCopied ? "Image Copied" : "Copy Graph as Image")
                    .localizedInterfaceText
            )
            .accessibilityLabel(
                (imageCopied ? "Image Copied" : "Copy Graph as Image")
                    .localizedInterfaceText
            )

            if openToolInWindow.isAvailable {
                Button {
                    openToolInWindow(.functionGraphs)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .toolPouchCircleSurface()
                .help("Open Graph in Window".localizedInterfaceText)
                .accessibilityLabel("Open Graph in Window".localizedInterfaceText)
            }
        }
    }

    private var syntaxHint: some View {
        Text("Use x, π, e, sin, cos, tan, sqrt, ln, log, abs, and exp. Implicit multiplication such as 2x is supported.")
            .font(ToolPouchLayout.Typography.compactSupporting)
            .foregroundStyle(theme.colors.secondaryText.color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func updateGraph() {
        selectedPoint = nil
        guard let minimum = parseBound(lowerBound),
              let maximum = parseBound(upperBound),
              minimum < maximum else {
            graph = nil
            errorMessage = FunctionGraphError.invalidRange.localizedDescription
            return
        }

        do {
            graph = try sampler.sample(
                expression: expression,
                xRange: minimum...maximum,
                angleUnit: angleUnit,
                sampleCount: 401
            )
            errorMessage = nil
        } catch {
            graph = nil
            errorMessage = error.localizedDescription
        }
    }

    private func selectPoint(at horizontalPosition: CGFloat, proxy: ChartProxy) {
        guard let graph,
              let x = proxy.value(atX: horizontalPosition, as: Double.self) else {
            selectedPoint = nil
            return
        }
        selectedPoint = graph.points.min {
            abs($0.x - x) < abs($1.x - x)
        }
    }

    private func parseBound(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private func format(_ value: Double) -> String {
        String(format: "%.6g", locale: Locale.current, value)
    }

    private func expandedGraphHeight(for availableHeight: CGFloat) -> CGFloat {
        // Reserve room for the controls, card spacing, and the syntax hint
        // below the graph so the final line stays visible without scrolling.
        min(max(availableHeight - 365, 220), 560)
    }

    private func copyGraphImage(_ graph: FunctionGraph) {
        guard FunctionGraphImageExporter.copy(
            graph: graph,
            expression: graph.expression,
            angleUnit: graph.angleUnit,
            theme: theme
        ) else { return }

        imageCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            imageCopied = false
        }
    }
}

private struct FunctionGraphHeightModifier: ViewModifier {
    let height: CGFloat?

    func body(content: Content) -> some View {
        if let height {
            content.frame(height: height)
        } else {
            content.frame(minHeight: 230, idealHeight: 260, maxHeight: 320)
        }
    }
}

private enum FunctionGraphExample: String, CaseIterable, Identifiable {
    case sine
    case parabola
    case exponential
    case reciprocal

    var id: Self { self }

    var title: String {
        switch self {
        case .sine: "Sine"
        case .parabola: "Parabola"
        case .exponential: "Exponential"
        case .reciprocal: "Reciprocal"
        }
    }

    var expression: String {
        switch self {
        case .sine: "sin(x)"
        case .parabola: "x^2"
        case .exponential: "exp(x)"
        case .reciprocal: "1/x"
        }
    }

    var lowerBound: String {
        switch self {
        case .sine: "-10"
        case .parabola: "-5"
        case .exponential: "-3"
        case .reciprocal: "-10"
        }
    }

    var upperBound: String {
        switch self {
        case .sine: "10"
        case .parabola: "5"
        case .exponential: "3"
        case .reciprocal: "10"
        }
    }
}
