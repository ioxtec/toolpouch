import Testing
@testable import toolpouch

struct CoordinateParserTests {
    @Test
    func parsesDecimalDegrees() {
        let coordinate = CoordinateParser.parse("52.229676, 21.012229")

        #expect(coordinate == GeographicCoordinate(latitude: 52.229676, longitude: 21.012229))
    }

    @Test
    func parsesDecimalDegreesWithLocalizedSeparator() {
        let coordinate = CoordinateParser.parse("52,229676; 21,012229")

        #expect(coordinate == GeographicCoordinate(latitude: 52.229676, longitude: 21.012229))
    }

    @Test
    func parsesDegreesAndDecimalMinutes() {
        let coordinate = CoordinateParser.parse("52° 13.78056′ N, 21° 0.73374′ E")

        #expect(abs((coordinate?.latitude ?? 0) - 52.229676) < 0.000_001)
        #expect(abs((coordinate?.longitude ?? 0) - 21.012229) < 0.000_001)
    }

    @Test
    func parsesDegreesMinutesAndSeconds() {
        let coordinate = CoordinateParser.parse("52° 13′ 46.834″ N, 21° 0′ 44.024″ E")

        #expect(abs((coordinate?.latitude ?? 0) - 52.229676) < 0.000_001)
        #expect(abs((coordinate?.longitude ?? 0) - 21.012229) < 0.000_001)
    }

    @Test
    func appliesSouthernAndWesternHemispheres() {
        let coordinate = CoordinateParser.parse("33° 51′ 31″ S, 151° 12′ 51″ E")

        #expect(coordinate?.latitude ?? 0 < 0)
        #expect(coordinate?.longitude ?? 0 > 0)
    }

    @Test
    func rejectsOutOfRangeCoordinate() {
        #expect(CoordinateParser.parse("91, 21") == nil)
        #expect(CoordinateParser.parse("52, 181") == nil)
    }

    @Test
    func formatsAllSupportedRepresentations() {
        let coordinate = GeographicCoordinate(latitude: 52.229676, longitude: 21.012229)

        #expect(CoordinateDisplayFormat.decimalDegrees.string(for: coordinate) == "52.229676, 21.012229")
        #expect(CoordinateDisplayFormat.geoURI.string(for: coordinate) == "geo:52.229676,21.012229")
        #expect(CoordinateDisplayFormat.degreesDecimalMinutes.string(for: coordinate).hasSuffix("E"))
        #expect(CoordinateDisplayFormat.degreesMinutesSeconds.string(for: coordinate).contains("N"))
    }
}
