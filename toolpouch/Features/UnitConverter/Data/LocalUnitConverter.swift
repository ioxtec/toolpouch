nonisolated struct LocalUnitConverter: UnitConverting {
    func convert(
        _ value: Double,
        from source: ConversionUnit,
        to destination: ConversionUnit
    ) throws -> Double {
        guard value.isFinite else { throw UnitConversionError.invalidValue }
        guard source.category == destination.category else {
            throw UnitConversionError.incompatibleUnits
        }
        guard source != destination else { return value }

        let baseValue = try valueInBaseUnit(value, unit: source)
        let result = try valueFromBaseUnit(baseValue, unit: destination)
        guard result.isFinite else { throw UnitConversionError.invalidValue }
        return result
    }

    private func valueInBaseUnit(
        _ value: Double,
        unit: ConversionUnit
    ) throws -> Double {
        switch unit {
        case .celsius:
            return value
        case .fahrenheit:
            return (value - 32) * 5 / 9
        case .kelvin:
            return value - 273.15
        case .literPer100Kilometers:
            return try positiveFuelValue(value)
        case .kilometerPerLiter:
            return 100 / (try positiveFuelValue(value))
        case .milePerUSGallon:
            return 235.214583 / (try positiveFuelValue(value))
        case .milePerImperialGallon:
            return 282.480936 / (try positiveFuelValue(value))
        default:
            return value * linearFactor(for: unit)
        }
    }

    private func valueFromBaseUnit(
        _ value: Double,
        unit: ConversionUnit
    ) throws -> Double {
        switch unit {
        case .celsius:
            return value
        case .fahrenheit:
            return value * 9 / 5 + 32
        case .kelvin:
            return value + 273.15
        case .literPer100Kilometers:
            return try positiveFuelValue(value)
        case .kilometerPerLiter:
            return 100 / (try positiveFuelValue(value))
        case .milePerUSGallon:
            return 235.214583 / (try positiveFuelValue(value))
        case .milePerImperialGallon:
            return 282.480936 / (try positiveFuelValue(value))
        default:
            return value / linearFactor(for: unit)
        }
    }

    private func positiveFuelValue(_ value: Double) throws -> Double {
        guard value > 0 else { throw UnitConversionError.zeroFuelEfficiency }
        return value
    }

    private func linearFactor(for unit: ConversionUnit) -> Double {
        switch unit {
        case .millimeter: 0.001
        case .centimeter: 0.01
        case .meter: 1
        case .kilometer: 1_000
        case .inch: 0.0254
        case .foot: 0.3048
        case .yard: 0.9144
        case .mile: 1_609.344
        case .milligram: 0.000_001
        case .gram: 0.001
        case .kilogram: 1
        case .metricTonne: 1_000
        case .ounce: 0.028_349_523_125
        case .pound: 0.453_592_37
        case .stone: 6.350_293_18
        case .milliliter, .milliliterCooking: 0.001
        case .liter, .literCooking: 1
        case .cubicMeter: 1_000
        case .usFluidOunce, .usFluidOunceCooking: 0.029_573_529_562_5
        case .usPint: 0.473_176_473
        case .usGallon: 3.785_411_784
        case .imperialGallon: 4.546_09
        case .squareMeter: 1
        case .squareKilometer: 1_000_000
        case .hectare: 10_000
        case .squareFoot: 0.092_903_04
        case .squareYard: 0.836_127_36
        case .acre: 4_046.856_422_4
        case .squareMile: 2_589_988.110_336
        case .meterPerSecond: 1
        case .kilometerPerHour: 0.277_777_777_777_778
        case .milePerHour: 0.447_04
        case .knot: 0.514_444_444_444_444
        case .teaspoon: 0.004_928_921_593_75
        case .tablespoon: 0.014_786_764_781_25
        case .usCup: 0.236_588_236_5
        case .byte: 1
        case .kilobyte: 1_000
        case .megabyte: 1_000_000
        case .gigabyte: 1_000_000_000
        case .terabyte: 1_000_000_000_000
        case .kibibyte: 1_024
        case .mebibyte: 1_048_576
        case .gibibyte: 1_073_741_824
        case .tebibyte: 1_099_511_627_776
        case .celsius, .fahrenheit, .kelvin,
             .literPer100Kilometers, .kilometerPerLiter,
             .milePerUSGallon, .milePerImperialGallon:
            1
        }
    }
}
