import Foundation
import SwiftUI

struct ScientificCalculatorView: View {
    private let calculator: any ScientificCalculating

    @Environment(\.appTheme) private var theme
    @State private var angleUnit = ScientificAngleUnit.degrees
    @State private var precision = 10
    @State private var expression = ""
    @State private var result: Double?
    @State private var resultText = "0"
    @State private var errorMessage: String?
    @State private var answer: Double?
    @State private var history: [ScientificCalculationHistoryItem] = []

    init(calculator: any ScientificCalculating) {
        self.calculator = calculator
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                ScreenHeader(
                    title: "Scientific Calculator",
                    subtitle: "Calculate expressions with functions, constants, and angle modes."
                )
                calculatorCard
                if !history.isEmpty {
                    historyCard
                }
            }
        }
        .scrollIndicators(.never)
        .onChange(of: precision) { refreshDisplayedResult() }
    }

    private var calculatorCard: some View {
        ToolSectionCard {
            modeControls
            display
            keypad
        }
    }

    private var modeControls: some View {
        HStack(spacing: ToolPouchLayout.Spacing.medium) {
            ToolPouchSegmentedControl(
                ScientificAngleUnit.allCases,
                selection: $angleUnit,
                title: \.title
            )

            Picker("Precision", selection: $precision) {
                ForEach([6, 8, 10, 12], id: \.self) { digits in
                    Text("\(digits)").tag(digits)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .toolPouchControlSurface(
                minimumHeight: ToolPouchLayout.Control.compactHeight,
                horizontalPadding: ToolPouchLayout.Spacing.medium
            )
            .help("Precision")
            .accessibilityLabel("Precision")
        }
    }

    private var display: some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.small) {
            TextField("Enter an expression", text: $expression)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit(calculate)
                .accessibilityLabel("Calculator expression")

            Divider()

            HStack(alignment: .firstTextBaseline, spacing: ToolPouchLayout.Spacing.medium) {
                Text(resultText)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(
                        errorMessage == nil
                            ? theme.colors.primaryText.color
                            : theme.colors.danger.color
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if errorMessage == nil, result != nil {
                    CopyButton(value: resultText)
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(ToolPouchLayout.Typography.compactSupporting)
                    .foregroundStyle(theme.colors.danger.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(ToolPouchLayout.Spacing.medium)
        .frame(minHeight: 82)
        .toolPouchSurface(interactive: true, cornerRadius: ToolPouchLayout.Radius.control)
    }

    private var keypad: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: ToolPouchLayout.Spacing.small),
                count: 5
            ),
            spacing: ToolPouchLayout.Spacing.small
        ) {
            ForEach(CalculatorKey.allCases) { key in
                Button {
                    handle(key)
                } label: {
                    Group {
                        if key == .delete {
                            Image(systemName: "delete.left")
                        } else {
                            Text(key.label)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CalculatorKeyButtonStyle(kind: key.kind))
                .help(key.help.localizedInterfaceText)
                .accessibilityLabel(key.help.localizedInterfaceText)
            }
        }
    }

    private var historyCard: some View {
        ToolSectionCard {
            HStack {
                Text("History".localizedInterfaceText)
                    .font(ToolPouchLayout.Typography.sectionTitle)
                Spacer()
                Button("Clear History") { history.removeAll() }
                    .buttonStyle(.borderless)
                    .font(ToolPouchLayout.Typography.supporting)
            }

            ForEach(Array(history.enumerated()), id: \.element.id) { index, item in
                if index > 0 { Divider() }
                Button {
                    expression = item.expression
                    result = item.result
                    resultText = format(item.result)
                    errorMessage = nil
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.expression)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(theme.colors.secondaryText.color)
                            .lineLimit(1)
                        Text(format(item.result))
                            .font(ToolPouchLayout.Typography.value)
                            .foregroundStyle(theme.colors.primaryText.color)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handle(_ key: CalculatorKey) {
        switch key {
        case .clear:
            expression = ""
            result = nil
            resultText = "0"
            errorMessage = nil
        case .delete:
            if !expression.isEmpty { expression.removeLast() }
            errorMessage = nil
        case .answer:
            insert("ans")
        case .sign:
            guard !expression.isEmpty else {
                expression = "-"
                return
            }
            expression = "-(\(expression))"
        case .equals:
            calculate()
        default:
            insert(key.insertion)
        }
    }

    private func insert(_ value: String) {
        expression.append(value)
        errorMessage = nil
    }

    private func calculate() {
        do {
            var variables: [String: Double] = [:]
            if let answer { variables["ans"] = answer }
            let value = try calculator.evaluate(
                expression,
                angleUnit: angleUnit,
                variables: variables
            )
            result = value
            answer = value
            resultText = format(value)
            errorMessage = nil

            let item = ScientificCalculationHistoryItem(
                expression: expression,
                result: value
            )
            history.removeAll { $0.expression == item.expression && $0.result == item.result }
            history.insert(item, at: 0)
            history = Array(history.prefix(6))
        } catch {
            result = nil
            resultText = "—"
            errorMessage = error.localizedDescription
        }
    }

    private func refreshDisplayedResult() {
        if let result { resultText = format(result) }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.*g", locale: Locale.current, precision, value)
    }
}

private struct ScientificCalculationHistoryItem: Identifiable {
    let id = UUID()
    let expression: String
    let result: Double
}

private enum CalculatorKeyKind {
    case number
    case operation
    case function
    case destructive
    case equals
}

private enum CalculatorKey: String, CaseIterable, Identifiable {
    case sine, cosine, tangent, naturalLog, commonLog
    case seven, eight, nine, divide, openParenthesis
    case four, five, six, multiply, closeParenthesis
    case one, two, three, subtract, power
    case zero, decimal, pi, add, squareRoot
    case clear, delete, answer, sign, equals

    var id: Self { self }

    var label: String {
        switch self {
        case .sine: "sin"
        case .cosine: "cos"
        case .tangent: "tan"
        case .naturalLog: "ln"
        case .commonLog: "log"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .divide: "÷"
        case .openParenthesis: "("
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .multiply: "×"
        case .closeParenthesis: ")"
        case .one: "1"
        case .two: "2"
        case .three: "3"
        case .subtract: "−"
        case .power: "xʸ"
        case .zero: "0"
        case .decimal: "."
        case .pi: "π"
        case .add: "+"
        case .squareRoot: "√"
        case .clear: "AC"
        case .delete: ""
        case .answer: "Ans"
        case .sign: "+/−"
        case .equals: "="
        }
    }

    var insertion: String {
        switch self {
        case .sine: "sin("
        case .cosine: "cos("
        case .tangent: "tan("
        case .naturalLog: "ln("
        case .commonLog: "log("
        case .divide: "/"
        case .multiply: "*"
        case .subtract: "-"
        case .power: "^"
        case .squareRoot: "sqrt("
        default: label
        }
    }

    var kind: CalculatorKeyKind {
        switch self {
        case .sine, .cosine, .tangent, .naturalLog, .commonLog, .squareRoot:
            .function
        case .divide, .multiply, .subtract, .power, .add,
             .openParenthesis, .closeParenthesis, .sign:
            .operation
        case .clear, .delete:
            .destructive
        case .equals:
            .equals
        default:
            .number
        }
    }

    var help: String {
        switch self {
        case .clear: "Clear calculator"
        case .delete: "Delete last character"
        case .answer: "Previous answer"
        case .sign: "Change sign"
        case .equals: "Calculate"
        default: label
        }
    }
}

private struct CalculatorKeyButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    let kind: CalculatorKeyKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(minHeight: 34)
            .background(
                backgroundColor.opacity(configuration.isPressed ? 0.72 : 1),
                in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
                    .stroke(borderColor, lineWidth: 1)
            }
            .contentShape(.rect)
    }

    private var foregroundColor: Color {
        switch kind {
        case .equals, .function, .operation:
            theme.colors.primaryAccent.color
        case .destructive:
            theme.colors.danger.color
        case .number:
            theme.colors.primaryText.color
        }
    }

    private var backgroundColor: Color {
        kind == .equals
            ? theme.colors.accentButtonBackground.color
            : theme.colors.recessedSurface.color
    }

    private var borderColor: Color {
        kind == .equals
            ? theme.colors.primaryAccent.color.opacity(0.28)
            : theme.colors.border.color.opacity(0.45)
    }
}
