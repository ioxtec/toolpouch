nonisolated enum ConversionUnit: String, CaseIterable, Identifiable, Sendable {
    case millimeter
    case centimeter
    case meter
    case kilometer
    case inch
    case foot
    case yard
    case mile

    case milligram
    case gram
    case kilogram
    case metricTonne
    case ounce
    case pound
    case stone

    case celsius
    case fahrenheit
    case kelvin

    case milliliter
    case liter
    case cubicMeter
    case usFluidOunce
    case usPint
    case usGallon
    case imperialGallon

    case squareMeter
    case squareKilometer
    case hectare
    case squareFoot
    case squareYard
    case acre
    case squareMile

    case meterPerSecond
    case kilometerPerHour
    case milePerHour
    case knot

    case milliliterCooking
    case teaspoon
    case tablespoon
    case usCup
    case usFluidOunceCooking

    case literPer100Kilometers
    case kilometerPerLiter
    case milePerUSGallon
    case milePerImperialGallon

    case byte
    case kilobyte
    case megabyte
    case gigabyte
    case terabyte
    case kibibyte
    case mebibyte
    case gibibyte
    case tebibyte

    var id: Self { self }

    var category: UnitConversionCategory {
        switch self {
        case .millimeter, .centimeter, .meter, .kilometer,
             .inch, .foot, .yard, .mile:
            .length
        case .milligram, .gram, .kilogram, .metricTonne,
             .ounce, .pound, .stone:
            .weight
        case .celsius, .fahrenheit, .kelvin:
            .temperature
        case .milliliter, .liter, .cubicMeter, .usFluidOunce,
             .usPint, .usGallon, .imperialGallon:
            .volume
        case .squareMeter, .squareKilometer, .hectare, .squareFoot,
             .squareYard, .acre, .squareMile:
            .area
        case .meterPerSecond, .kilometerPerHour, .milePerHour, .knot:
            .speed
        case .milliliterCooking, .teaspoon, .tablespoon,
             .usCup, .usFluidOunceCooking:
            .cooking
        case .literPer100Kilometers, .kilometerPerLiter,
             .milePerUSGallon, .milePerImperialGallon:
            .fuelEconomy
        case .byte, .kilobyte, .megabyte, .gigabyte, .terabyte,
             .kibibyte, .mebibyte, .gibibyte, .tebibyte:
            .data
        }
    }

    var title: String {
        switch self {
        case .millimeter: "Millimeters"
        case .centimeter: "Centimeters"
        case .meter: "Meters"
        case .kilometer: "Kilometers"
        case .inch: "Inches"
        case .foot: "Feet"
        case .yard: "Yards"
        case .mile: "Miles"
        case .milligram: "Milligrams"
        case .gram: "Grams"
        case .kilogram: "Kilograms"
        case .metricTonne: "Metric Tonnes"
        case .ounce: "Ounces"
        case .pound: "Pounds"
        case .stone: "Stone"
        case .celsius: "Celsius"
        case .fahrenheit: "Fahrenheit"
        case .kelvin: "Kelvin"
        case .milliliter: "Milliliters"
        case .liter: "Liters"
        case .cubicMeter: "Cubic Meters"
        case .usFluidOunce: "US Fluid Ounces"
        case .usPint: "US Pints"
        case .usGallon: "US Gallons"
        case .imperialGallon: "Imperial Gallons"
        case .squareMeter: "Square Meters"
        case .squareKilometer: "Square Kilometers"
        case .hectare: "Hectares"
        case .squareFoot: "Square Feet"
        case .squareYard: "Square Yards"
        case .acre: "Acres"
        case .squareMile: "Square Miles"
        case .meterPerSecond: "Meters per Second"
        case .kilometerPerHour: "Kilometers per Hour"
        case .milePerHour: "Miles per Hour"
        case .knot: "Knots"
        case .milliliterCooking: "Milliliters"
        case .teaspoon: "Teaspoons"
        case .tablespoon: "Tablespoons"
        case .usCup: "US Cups"
        case .usFluidOunceCooking: "US Fluid Ounces"
        case .literPer100Kilometers: "Liters per 100 km"
        case .kilometerPerLiter: "Kilometers per Liter"
        case .milePerUSGallon: "Miles per US Gallon"
        case .milePerImperialGallon: "Miles per Imperial Gallon"
        case .byte: "Bytes"
        case .kilobyte: "Kilobytes"
        case .megabyte: "Megabytes"
        case .gigabyte: "Gigabytes"
        case .terabyte: "Terabytes"
        case .kibibyte: "Kibibytes"
        case .mebibyte: "Mebibytes"
        case .gibibyte: "Gibibytes"
        case .tebibyte: "Tebibytes"
        }
    }

    var symbol: String {
        switch self {
        case .millimeter: "mm"
        case .centimeter: "cm"
        case .meter: "m"
        case .kilometer: "km"
        case .inch: "in"
        case .foot: "ft"
        case .yard: "yd"
        case .mile: "mi"
        case .milligram: "mg"
        case .gram: "g"
        case .kilogram: "kg"
        case .metricTonne: "t"
        case .ounce: "oz"
        case .pound: "lb"
        case .stone: "st"
        case .celsius: "°C"
        case .fahrenheit: "°F"
        case .kelvin: "K"
        case .milliliter, .milliliterCooking: "mL"
        case .liter: "L"
        case .cubicMeter: "m³"
        case .usFluidOunce, .usFluidOunceCooking: "US fl oz"
        case .usPint: "US pt"
        case .usGallon: "US gal"
        case .imperialGallon: "imp gal"
        case .squareMeter: "m²"
        case .squareKilometer: "km²"
        case .hectare: "ha"
        case .squareFoot: "ft²"
        case .squareYard: "yd²"
        case .acre: "ac"
        case .squareMile: "mi²"
        case .meterPerSecond: "m/s"
        case .kilometerPerHour: "km/h"
        case .milePerHour: "mph"
        case .knot: "kn"
        case .teaspoon: "tsp"
        case .tablespoon: "tbsp"
        case .usCup: "US cup"
        case .literPer100Kilometers: "L/100 km"
        case .kilometerPerLiter: "km/L"
        case .milePerUSGallon: "US mpg"
        case .milePerImperialGallon: "imp mpg"
        case .byte: "B"
        case .kilobyte: "KB"
        case .megabyte: "MB"
        case .gigabyte: "GB"
        case .terabyte: "TB"
        case .kibibyte: "KiB"
        case .mebibyte: "MiB"
        case .gibibyte: "GiB"
        case .tebibyte: "TiB"
        }
    }
}
