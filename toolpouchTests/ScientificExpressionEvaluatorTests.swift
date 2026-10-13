import Foundation
import Testing
@testable import toolpouch

struct ScientificExpressionEvaluatorTests {
    private let calculator = ScientificExpressionEvaluator()

    @Test
    func rejectsExcessiveInputBeforeRecursing() {
        for expression in [String(repeating: "1", count: 1_025), String(repeating: "(", count: 33) + "1" + String(repeating: ")", count: 33), String(repeating: "-", count: 129) + "1"] {
            #expect(throws: ScientificCalculationError.expressionTooComplex) {
                try calculator.evaluate(expression, angleUnit: .radians)
            }
        }
    }

    @Test
    func respectsPrecedenceAndParentheses() throws {
        #expect(try calculator.evaluate("2 + 3 * 4", angleUnit: .radians) == 14)
        #expect(try calculator.evaluate("(2 + 3) * 4", angleUnit: .radians) == 20)
        #expect(try calculator.evaluate("2^3^2", angleUnit: .radians) == 512)
        #expect(try calculator.evaluate("-2^2", angleUnit: .radians) == -4)
    }

    @Test
    func evaluatesConstantsAndScientificFunctions() throws {
        let value = try calculator.evaluate(
            "sqrt(16) + ln(e) + log(100)",
            angleUnit: .radians
        )
        #expect(abs(value - 7) < 0.000_000_001)
        #expect(
            abs(
                try calculator.evaluate("2π", angleUnit: .radians)
                    - 2 * Double.pi
            ) < 0.000_000_001
        )
    }

    @Test
    func supportsDegreeAndRadianAngleModes() throws {
        let degrees = try calculator.evaluate("sin(30)", angleUnit: .degrees)
        let radians = try calculator.evaluate("cos(pi)", angleUnit: .radians)

        #expect(abs(degrees - 0.5) < 0.000_000_001)
        #expect(abs(radians + 1) < 0.000_000_001)
    }

    @Test
    func acceptsVariablesForAnswersAndFutureGraphs() throws {
        let answer = try calculator.evaluate(
            "ans * 2",
            angleUnit: .radians,
            variables: ["ans": 21]
        )
        let point = try calculator.evaluate(
            "x^2 + 1",
            angleUnit: .radians,
            variables: ["x": 3]
        )

        #expect(answer == 42)
        #expect(point == 10)
    }

    @Test
    func acceptsACommaAsDecimalSeparator() throws {
        #expect(try calculator.evaluate("1,5 * 2", angleUnit: .radians) == 3)
    }

    @Test
    func reportsInvalidOperations() {
        #expect(throws: ScientificCalculationError.divisionByZero) {
            try calculator.evaluate("1 / 0", angleUnit: .radians)
        }
        #expect(throws: ScientificCalculationError.domainError) {
            try calculator.evaluate("sqrt(-1)", angleUnit: .radians)
        }
        #expect(throws: ScientificCalculationError.missingClosingParenthesis) {
            try calculator.evaluate("sin(1", angleUnit: .radians)
        }
    }
}
