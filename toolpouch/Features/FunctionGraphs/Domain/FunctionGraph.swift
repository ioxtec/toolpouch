import Foundation

nonisolated struct FunctionGraph: Sendable {
    let expression: String
    let angleUnit: ScientificAngleUnit
    let points: [FunctionGraphPoint]
    let xDomain: ClosedRange<Double>
    let yDomain: ClosedRange<Double>
}

nonisolated struct FunctionGraphPoint: Identifiable, Sendable {
    let id: Int
    let x: Double
    let y: Double
    let segment: Int
}
