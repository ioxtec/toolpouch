import Foundation

nonisolated enum UnitConversionError: LocalizedError, Equatable, Sendable {
    case incompatibleUnits
    case invalidValue
    case zeroFuelEfficiency

    var errorDescription: String? {
        switch self {
        case .incompatibleUnits:
            "Choose units from the same category."
        case .invalidValue:
            "Enter a finite number."
        case .zeroFuelEfficiency:
            "Fuel economy must be greater than zero."
        }
    }
}
