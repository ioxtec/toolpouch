import Foundation
import Testing
@testable import toolpouch

struct LocalFunctionGraphSamplerTests {
    private let sampler = LocalFunctionGraphSampler(
        calculator: ScientificExpressionEvaluator()
    )

    @Test
    func samplesAFunctionAcrossTheRequestedRange() throws {
        let graph = try sampler.sample(
            expression: "x^2",
            xRange: -2...2,
            angleUnit: .radians,
            sampleCount: 5
        )

        #expect(graph.points.count == 5)
        #expect(graph.expression == "x^2")
        #expect(graph.angleUnit == .radians)
        #expect(graph.points.first?.x == -2)
        #expect(graph.points.first?.y == 4)
        #expect(graph.points[2].y == 0)
        #expect(graph.points.last?.x == 2)
    }

    @Test
    func separatesUndefinedPartsInsteadOfJoiningAcrossThem() throws {
        let graph = try sampler.sample(
            expression: "1/x",
            xRange: -1...1,
            angleUnit: .radians,
            sampleCount: 5
        )

        #expect(graph.points.count == 4)
        #expect(Set(graph.points.map(\.segment)).count == 2)
        #expect(!graph.points.contains { !$0.y.isFinite })
    }

    @Test
    func calculatesAReadableDomainForConstantFunctions() throws {
        let graph = try sampler.sample(
            expression: "2",
            xRange: -1...1,
            angleUnit: .radians,
            sampleCount: 10
        )

        #expect(graph.yDomain.lowerBound < 2)
        #expect(graph.yDomain.upperBound > 2)
    }

    @Test
    func rejectsExpressionsWithoutDrawableValues() {
        #expect(throws: FunctionGraphError.noDrawableValues) {
            try sampler.sample(
                expression: "sqrt(-1)",
                xRange: -1...1,
                angleUnit: .radians,
                sampleCount: 10
            )
        }
    }
}
