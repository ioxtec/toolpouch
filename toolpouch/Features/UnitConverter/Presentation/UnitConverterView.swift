import Foundation
import SwiftUI

struct UnitConverterView: View {
    private enum Side {
        case left
        case right
    }

    private let converter: any UnitConverting

    @State private var category = UnitConversionCategory.length
    @State private var leftUnit = ConversionUnit.kilometer
    @State private var rightUnit = ConversionUnit.mile
    @State private var leftValue = "1"
    @State private var rightValue = ""
    @State private var sourceSide = Side.left
    @State private var errorMessage: String?

    init(converter: any UnitConverting) {
        self.converter = converter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                #if os(watchOS)
                watchHeader
                #else
                ScreenHeader(
                    title: "Unit Converter",
                    subtitle: "Edit either value to convert in both directions."
                )
                #endif

                converterPanel
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .task {
            recalculate(from: .left)
        }
    }

    #if os(watchOS)
    private var watchHeader: some View {
        Text("Unit Converter")
            .font(.headline)
    }
    #endif

    private var converterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            categoryPicker
            Divider()
            conversionFields

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var categoryPicker: some View {
        Picker("Category", selection: categoryBinding) {
            ForEach(UnitConversionCategory.allCases) { category in
                Label(category.title, systemImage: category.systemImage)
                    .tag(category)
            }
        }
        #if os(watchOS)
        .pickerStyle(.navigationLink)
        #else
        .pickerStyle(.menu)
        #endif
    }

    @ViewBuilder
    private var conversionFields: some View {
        #if os(watchOS)
        VStack(spacing: 10) {
            valuePanel(side: .left)
            swapButton(vertical: true)
            valuePanel(side: .right)
        }
        #else
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                valuePanel(side: .left)
                    .frame(minWidth: 210)
                swapButton(vertical: false)
                valuePanel(side: .right)
                    .frame(minWidth: 210)
            }

            VStack(spacing: 10) {
                valuePanel(side: .left)
                swapButton(vertical: true)
                valuePanel(side: .right)
            }
        }
        #endif
    }

    private func valuePanel(side: Side) -> some View {
        let unit = side == .left ? leftUnit : rightUnit

        return VStack(alignment: .leading, spacing: 10) {
            Picker(
                side == .left ? "From" : "To",
                selection: unitBinding(for: side)
            ) {
                ForEach(category.units) { unit in
                    Text("\(unit.title) (\(unit.symbol))")
                        .tag(unit)
                }
            }
            .labelsHidden()

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0", text: valueBinding(for: side))
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .textFieldStyle(.plain)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                Text(unit.symbol)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                #if !os(watchOS)
                if !(side == .left ? leftValue : rightValue).isEmpty {
                    CopyButton(value: side == .left ? leftValue : rightValue)
                }
                #endif
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            if let alternative = alternativeRepresentation(for: side) {
                Text(alternative)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Convenient equivalent: \(alternative)")
            }
        }
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func swapButton(vertical: Bool) -> some View {
        Button {
            swapSides()
        } label: {
            Image(systemName: vertical ? "arrow.up.arrow.down" : "arrow.left.arrow.right")
                .toolPouchIcon(.medium, weight: .semibold)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.borderless)
        .help("Swap units")
        .accessibilityLabel("Swap units")
    }

    private var categoryBinding: Binding<UnitConversionCategory> {
        Binding(
            get: { category },
            set: { newCategory in
                category = newCategory
                let defaults = newCategory.defaultPair
                leftUnit = defaults.left
                rightUnit = defaults.right
                sourceSide = .left
                recalculate(from: .left)
            }
        )
    }

    private func unitBinding(for side: Side) -> Binding<ConversionUnit> {
        Binding(
            get: { side == .left ? leftUnit : rightUnit },
            set: { unit in
                if side == .left {
                    leftUnit = unit
                } else {
                    rightUnit = unit
                }
                recalculate(from: sourceSide)
            }
        )
    }

    private func valueBinding(for side: Side) -> Binding<String> {
        Binding(
            get: { side == .left ? leftValue : rightValue },
            set: { value in
                sourceSide = side
                if side == .left {
                    leftValue = value
                } else {
                    rightValue = value
                }
                recalculate(from: side)
            }
        )
    }

    private func swapSides() {
        (leftUnit, rightUnit) = (rightUnit, leftUnit)
        (leftValue, rightValue) = (rightValue, leftValue)
        sourceSide = sourceSide == .left ? .right : .left
        errorMessage = nil
    }

    private func recalculate(from side: Side) {
        let sourceText = side == .left ? leftValue : rightValue
        guard !sourceText.trimmingCharacters(in: .whitespaces).isEmpty else {
            if side == .left {
                rightValue = ""
            } else {
                leftValue = ""
            }
            errorMessage = nil
            return
        }

        guard let value = numberFormatter.number(from: sourceText)?.doubleValue else {
            clearDestination(for: side)
            errorMessage = "Enter a valid number."
            return
        }

        do {
            let result: Double
            if side == .left {
                result = try converter.convert(value, from: leftUnit, to: rightUnit)
                rightValue = formatted(result)
            } else {
                result = try converter.convert(value, from: rightUnit, to: leftUnit)
                leftValue = formatted(result)
            }
            errorMessage = nil
        } catch {
            clearDestination(for: side)
            errorMessage = error.localizedDescription
        }
    }

    private func clearDestination(for side: Side) {
        if side == .left {
            rightValue = ""
        } else {
            leftValue = ""
        }
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private func formatted(_ value: Double) -> String {
        UnitConversionValueFormatter.string(from: value)
    }

    private func alternativeRepresentation(for side: Side) -> String? {
        let text = side == .left ? leftValue : rightValue
        let unit = side == .left ? leftUnit : rightUnit
        guard let value = numberFormatter.number(from: text)?.doubleValue else {
            return nil
        }

        return UnitConversionAlternativeFormatter.string(
            from: value,
            unit: unit,
            converter: converter
        )
    }
}

/// Formats converted values with significant digits instead of a fixed number
/// of decimal places. Small units such as cups converted from milliliters need
/// more fractional places to survive a reverse conversion without visible
/// values such as 0.99999933 mL.
nonisolated enum UnitConversionValueFormatter {
    static func string(
        from value: Double,
        locale: Locale = .current
    ) -> String {
        value.formatted(
            .number
                .locale(locale)
                .grouping(.automatic)
                .precision(.significantDigits(1...12))
        )
    }
}
