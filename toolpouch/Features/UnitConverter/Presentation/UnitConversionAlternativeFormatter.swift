import Foundation

/// Produces one human-friendly equivalent without changing the unit selected
/// by the user. Full conversion precision remains in the editable fields; this
/// line is intentionally rounded and therefore uses the approximation sign.
nonisolated enum UnitConversionAlternativeFormatter {
    static func string(
        from value: Double,
        unit: ConversionUnit,
        converter: any UnitConverting,
        locale: Locale = .current
    ) -> String? {
        guard value.isFinite, value != 0 else { return nil }

        switch unit {
        case .milliliter, .milliliterCooking:
            return milliliterAlternative(
                value,
                cooking: unit == .milliliterCooking,
                converter: converter,
                locale: locale
            )
        case .liter, .literCooking:
            return literAlternative(
                value,
                cooking: unit == .literCooking,
                converter: converter,
                locale: locale
            )
        case .cubicMeter:
            return convertedAlternative(
                value,
                from: unit,
                to: .liter,
                when: abs(value) < 1,
                converter: converter,
                locale: locale
            )
        case .millimeter, .centimeter, .meter, .kilometer:
            return lengthAlternative(
                value,
                unit: unit,
                converter: converter,
                locale: locale
            )
        default:
            return nil
        }
    }

    private static func milliliterAlternative(
        _ value: Double,
        cooking: Bool,
        converter: any UnitConverting,
        locale: Locale
    ) -> String? {
        guard abs(value) >= 1_000 else { return nil }
        let literUnit: ConversionUnit = cooking ? .literCooking : .liter
        let milliliterUnit: ConversionUnit = cooking
            ? .milliliterCooking
            : .milliliter
        guard let liters = try? converter.convert(
            value,
            from: milliliterUnit,
            to: literUnit
        ) else {
            return nil
        }

        let decimalLiters = measurement(liters, symbol: "L", locale: locale)
        guard let compound = compoundLiterText(
            fromMilliliters: value,
            locale: locale
        ) else { return "≈ \(decimalLiters)" }
        guard compound != decimalLiters else { return "≈ \(decimalLiters)" }
        return "≈ \(decimalLiters) · \(compound)"
    }

    private static func literAlternative(
        _ value: Double,
        cooking: Bool,
        converter: any UnitConverting,
        locale: Locale
    ) -> String? {
        let source: ConversionUnit = cooking ? .literCooking : .liter
        let milliliters: ConversionUnit = cooking ? .milliliterCooking : .milliliter

        if abs(value) < 1 {
            return convertedAlternative(
                value,
                from: source,
                to: milliliters,
                when: true,
                converter: converter,
                locale: locale
            )
        }

        if !cooking, abs(value) >= 1_000 {
            return convertedAlternative(
                value,
                from: source,
                to: .cubicMeter,
                when: true,
                converter: converter,
                locale: locale
            )
        }

        guard let milliliterValue = try? converter.convert(
            value,
            from: source,
            to: milliliters
        ) else { return nil }
        guard let compound = compoundLiterText(
            fromMilliliters: milliliterValue,
            locale: locale
        ) else { return nil }
        let roundedLiters = measurement(value.rounded(), symbol: "L", locale: locale)
        return compound == roundedLiters ? nil : "≈ \(compound)"
    }

    private static func lengthAlternative(
        _ value: Double,
        unit: ConversionUnit,
        converter: any UnitConverting,
        locale: Locale
    ) -> String? {
        let magnitude = abs(value)
        let target: ConversionUnit?
        switch unit {
        case .millimeter:
            target = magnitude >= 1_000 ? .meter : nil
        case .centimeter:
            target = magnitude >= 100 ? .meter : (magnitude < 1 ? .millimeter : nil)
        case .meter:
            target = magnitude >= 1_000 ? .kilometer
                : (magnitude < 0.01 ? .millimeter : (magnitude < 1 ? .centimeter : nil))
        case .kilometer:
            target = magnitude < 1 ? .meter : nil
        default:
            target = nil
        }

        guard let target else { return nil }
        return convertedAlternative(
            value,
            from: unit,
            to: target,
            when: true,
            converter: converter,
            locale: locale
        )
    }

    private static func convertedAlternative(
        _ value: Double,
        from source: ConversionUnit,
        to destination: ConversionUnit,
        when condition: Bool,
        converter: any UnitConverting,
        locale: Locale
    ) -> String? {
        guard condition,
              let converted = try? converter.convert(
                  value,
                  from: source,
                  to: destination
              ) else { return nil }
        return "≈ \(measurement(converted, symbol: destination.symbol, locale: locale))"
    }

    private static func compoundLiterText(
        fromMilliliters value: Double,
        locale: Locale
    ) -> String? {
        guard abs(value) <= Double(UInt64.max) else { return nil }
        let sign = value < 0 ? "−" : ""
        let roundedMilliliters = UInt64(abs(value).rounded())
        let liters = roundedMilliliters / 1_000
        let milliliters = roundedMilliliters % 1_000
        let literText = liters.formatted(.number.locale(locale).grouping(.automatic))
        guard milliliters > 0 else { return "\(sign)\(literText) L" }
        let milliliterText = milliliters.formatted(
            .number.locale(locale).grouping(.automatic)
        )
        return "\(sign)\(literText) L \(milliliterText) mL"
    }

    private static func measurement(
        _ value: Double,
        symbol: String,
        locale: Locale
    ) -> String {
        let number = value.formatted(
            .number
                .locale(locale)
                .grouping(.automatic)
                .precision(.fractionLength(0...3))
        )
        return "\(number) \(symbol)"
    }
}
