import Foundation
import Testing
@testable import toolpouch

struct LocalUnitConverterTests {
    private let converter = LocalUnitConverter()

    @Test
    func convertsCommonMetricAndImperialUnits() throws {
        let miles = try converter.convert(1, from: .kilometer, to: .mile)
        let pounds = try converter.convert(1, from: .kilogram, to: .pound)

        #expect(abs(miles - 0.621_371_192_237_334) < 0.000_000_001)
        #expect(abs(pounds - 2.204_622_621_848_78) < 0.000_000_001)
        #expect(
            try converter.convert(100, from: .celsius, to: .fahrenheit) == 212
        )
    }

    @Test
    func convertsCookingAndStorageUnits() throws {
        let milliliters = try converter.convert(
            1,
            from: .usCup,
            to: .milliliterCooking
        )
        let gigabytes = try converter.convert(1, from: .gibibyte, to: .gigabyte)

        #expect(abs(milliliters - 236.588_236_5) < 0.000_001)
        #expect(abs(gigabytes - 1.073_741_824) < 0.000_000_001)
    }

    @Test
    func cookingIncludesLiters() throws {
        #expect(UnitConversionCategory.cooking.units.contains(.literCooking))

        let liters = try converter.convert(
            5,
            from: .usCup,
            to: .literCooking
        )
        #expect(abs(liters - 1.182_941_182_5) < 0.000_000_001)
    }

    @Test
    func convertsReciprocalFuelEconomy() throws {
        let milesPerGallon = try converter.convert(
            8,
            from: .literPer100Kilometers,
            to: .milePerUSGallon
        )

        #expect(abs(milesPerGallon - 29.401_822_875) < 0.000_001)
    }

    @Test
    func roundTripPreservesTheOriginalValue() throws {
        let miles = try converter.convert(42, from: .kilometer, to: .mile)
        let kilometers = try converter.convert(miles, from: .mile, to: .kilometer)

        #expect(abs(kilometers - 42) < 0.000_000_001)
    }

    @Test(arguments: [1.0, 2.0])
    func displayedCookingValueSurvivesReverseConversion(
        milliliters: Double
    ) throws {
        let cups = try converter.convert(
            milliliters,
            from: .milliliterCooking,
            to: .usCup
        )
        let displayedCups = UnitConversionValueFormatter.string(
            from: cups,
            locale: Locale(identifier: "en_US_POSIX")
        )
        let parser = NumberFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.numberStyle = .decimal
        let reparsedCups = try #require(
            parser.number(from: displayedCups)?.doubleValue
        )
        let convertedBack = try converter.convert(
            reparsedCups,
            from: .usCup,
            to: .milliliterCooking
        )

        #expect(
            UnitConversionValueFormatter.string(
                from: convertedBack,
                locale: Locale(identifier: "en_US_POSIX")
            ) == milliliters.formatted()
        )
    }

    @Test
    func smallCookingValuesKeepEnoughSignificantDigits() throws {
        let cups = try converter.convert(
            1,
            from: .milliliterCooking,
            to: .usCup
        )

        #expect(
            UnitConversionValueFormatter.string(
                from: cups,
                locale: Locale(identifier: "en_US_POSIX")
            ) == "0.00422675283773"
        )
    }

    @Test
    func largeMilliliterResultGetsFriendlyLiterRepresentations() {
        let result = UnitConversionAlternativeFormatter.string(
            from: 1_182.941_182_5,
            unit: .milliliterCooking,
            converter: converter,
            locale: Locale(identifier: "en_US_POSIX")
        )

        #expect(result == "≈ 1.183 L · 1 L 183 mL")
    }

    @Test
    func metricLengthGetsOneNaturalScaleAlternative() {
        let result = UnitConversionAlternativeFormatter.string(
            from: 1_182,
            unit: .millimeter,
            converter: converter,
            locale: Locale(identifier: "en_US_POSIX")
        )

        #expect(result == "≈ 1.182 m")
    }

    @Test
    func simpleMetricValuesDoNotAddRedundantAlternatives() {
        #expect(
            UnitConversionAlternativeFormatter.string(
                from: 500,
                unit: .milliliterCooking,
                converter: converter,
                locale: Locale(identifier: "en_US_POSIX")
            ) == nil
        )
    }

    @Test
    func rejectsInvalidConversions() {
        #expect(throws: UnitConversionError.incompatibleUnits) {
            try converter.convert(1, from: .kilometer, to: .kilogram)
        }
        #expect(throws: UnitConversionError.zeroFuelEfficiency) {
            try converter.convert(
                0,
                from: .literPer100Kilometers,
                to: .milePerUSGallon
            )
        }
    }
}
