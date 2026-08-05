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
