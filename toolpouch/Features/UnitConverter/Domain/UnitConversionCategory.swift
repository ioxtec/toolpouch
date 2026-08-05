nonisolated enum UnitConversionCategory: String, CaseIterable, Identifiable, Sendable {
    case length
    case weight
    case temperature
    case volume
    case area
    case speed
    case cooking
    case fuelEconomy
    case data

    var id: Self { self }

    var title: String {
        switch self {
        case .length: "Length"
        case .weight: "Weight"
        case .temperature: "Temperature"
        case .volume: "Volume"
        case .area: "Area"
        case .speed: "Speed"
        case .cooking: "Cooking"
        case .fuelEconomy: "Fuel Economy"
        case .data: "Data"
        }
    }

    var systemImage: String {
        switch self {
        case .length: "ruler"
        case .weight: "scalemass"
        case .temperature: "thermometer.medium"
        case .volume: "drop"
        case .area: "square.dashed"
        case .speed: "speedometer"
        case .cooking: "cup.and.saucer"
        case .fuelEconomy: "fuelpump"
        case .data: "externaldrive"
        }
    }

    var units: [ConversionUnit] {
        ConversionUnit.allCases.filter { $0.category == self }
    }

    var defaultPair: (left: ConversionUnit, right: ConversionUnit) {
        switch self {
        case .length: (.kilometer, .mile)
        case .weight: (.kilogram, .pound)
        case .temperature: (.celsius, .fahrenheit)
        case .volume: (.liter, .usGallon)
        case .area: (.squareMeter, .squareFoot)
        case .speed: (.kilometerPerHour, .milePerHour)
        case .cooking: (.milliliterCooking, .usCup)
        case .fuelEconomy: (.literPer100Kilometers, .milePerUSGallon)
        case .data: (.gigabyte, .gibibyte)
        }
    }
}
