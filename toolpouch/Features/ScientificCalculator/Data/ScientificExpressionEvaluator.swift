import Foundation

nonisolated struct ScientificExpressionEvaluator: ScientificCalculating {
    func evaluate(
        _ expression: String,
        angleUnit: ScientificAngleUnit,
        variables: [String: Double]
    ) throws -> Double {
        guard expression.count <= 1_024 else { throw ScientificCalculationError.expressionTooComplex }
        var depth = 0
        var operators = 0
        for character in expression {
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            if "+-−^".contains(character) { operators += 1 }
            guard depth <= 32, operators <= 128 else {
                throw ScientificCalculationError.expressionTooComplex
            }
        }
        var parser = Parser(
            expression: expression,
            angleUnit: angleUnit,
            variables: variables
        )
        let value = try parser.parse()
        guard value.isFinite else { throw ScientificCalculationError.nonFiniteResult }
        return value
    }
}

private nonisolated struct Parser {
    private let characters: [Character]
    private let angleUnit: ScientificAngleUnit
    private let variables: [String: Double]
    private var index = 0

    init(
        expression: String,
        angleUnit: ScientificAngleUnit,
        variables: [String: Double]
    ) {
        characters = Array(
            expression
                .replacingOccurrences(of: "×", with: "*")
                .replacingOccurrences(of: "÷", with: "/")
                .replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: "√", with: "sqrt")
                .replacingOccurrences(of: ",", with: ".")
        )
        self.angleUnit = angleUnit
        self.variables = variables.reduce(into: [:]) { result, item in
            result[item.key.lowercased()] = item.value
        }
    }

    mutating func parse() throws -> Double {
        skipWhitespace()
        guard !isAtEnd else { throw ScientificCalculationError.emptyExpression }
        let value = try parseExpression()
        skipWhitespace()
        guard isAtEnd else {
            throw ScientificCalculationError.unexpectedCharacter(characters[index])
        }
        return value
    }

    private mutating func parseExpression() throws -> Double {
        var value = try parseTerm()
        while true {
            if consume("+") {
                value += try parseTerm()
            } else if consume("-") {
                value -= try parseTerm()
            } else {
                return value
            }
        }
    }

    private mutating func parseTerm() throws -> Double {
        var value = try parseUnary()
        while true {
            if consume("*") {
                value *= try parseUnary()
            } else if consume("/") {
                let divisor = try parseUnary()
                guard divisor != 0 else { throw ScientificCalculationError.divisionByZero }
                value /= divisor
            } else if beginsImplicitFactor {
                value *= try parseUnary()
            } else {
                return value
            }
        }
    }

    private mutating func parseUnary() throws -> Double {
        if consume("+") { return try parseUnary() }
        if consume("-") { return try -parseUnary() }
        return try parsePower()
    }

    private mutating func parsePower() throws -> Double {
        let base = try parsePrimary()
        guard consume("^") else { return base }
        let exponent = try parseUnary()
        let value = Foundation.pow(base, exponent)
        guard !value.isNaN else { throw ScientificCalculationError.domainError }
        return value
    }

    private mutating func parsePrimary() throws -> Double {
        skipWhitespace()

        if consume("(") {
            let value = try parseExpression()
            guard consume(")") else {
                throw ScientificCalculationError.missingClosingParenthesis
            }
            return value
        }

        if let number = try parseNumber() {
            return number
        }

        if let identifier = parseIdentifier() {
            if consume("(") {
                let argument = try parseExpression()
                guard consume(")") else {
                    throw ScientificCalculationError.missingClosingParenthesis
                }
                return try evaluateFunction(identifier, argument: argument)
            }
            return try value(for: identifier)
        }

        throw ScientificCalculationError.unexpectedToken
    }

    private mutating func parseNumber() throws -> Double? {
        skipWhitespace()
        let start = index
        var hasDigit = false
        var hasDecimalPoint = false

        while let character = current {
            if character.isNumber {
                hasDigit = true
                index += 1
            } else if character == ".", !hasDecimalPoint {
                hasDecimalPoint = true
                index += 1
            } else {
                break
            }
        }

        if hasDigit, let character = current, character == "e" || character == "E" {
            let exponentStart = index
            index += 1
            if current == "+" || current == "-" { index += 1 }
            let digitsStart = index
            while current?.isNumber == true { index += 1 }
            if digitsStart == index { index = exponentStart }
        }

        guard hasDigit else {
            index = start
            return nil
        }

        let text = String(characters[start..<index])
        guard let value = Double(text) else {
            throw ScientificCalculationError.unexpectedToken
        }
        return value
    }

    private mutating func parseIdentifier() -> String? {
        skipWhitespace()
        let start = index
        while let character = current,
              character.isLetter || character == "π" || character == "_" {
            index += 1
        }
        guard start != index else { return nil }
        return String(characters[start..<index]).lowercased()
    }

    private func value(for identifier: String) throws -> Double {
        switch identifier {
        case "pi", "π": return Double.pi
        case "e": return Foundation.exp(Double(1))
        default:
            guard let value = variables[identifier] else {
                throw ScientificCalculationError.unknownSymbol(identifier)
            }
            return value
        }
    }

    private func evaluateFunction(
        _ identifier: String,
        argument: Double
    ) throws -> Double {
        let value: Double
        switch identifier {
        case "sin": value = Foundation.sin(toRadians(argument))
        case "cos": value = Foundation.cos(toRadians(argument))
        case "tan": value = Foundation.tan(toRadians(argument))
        case "asin":
            guard (-1...1).contains(argument) else {
                throw ScientificCalculationError.domainError
            }
            value = fromRadians(Foundation.asin(argument))
        case "acos":
            guard (-1...1).contains(argument) else {
                throw ScientificCalculationError.domainError
            }
            value = fromRadians(Foundation.acos(argument))
        case "atan": value = fromRadians(Foundation.atan(argument))
        case "sqrt":
            guard argument >= 0 else { throw ScientificCalculationError.domainError }
            value = Foundation.sqrt(argument)
        case "ln":
            guard argument > 0 else { throw ScientificCalculationError.domainError }
            value = Foundation.log(argument)
        case "log":
            guard argument > 0 else { throw ScientificCalculationError.domainError }
            value = Foundation.log10(argument)
        case "abs": value = Swift.abs(argument)
        case "exp": value = Foundation.exp(argument)
        default: throw ScientificCalculationError.unknownFunction(identifier)
        }
        guard value.isFinite else { throw ScientificCalculationError.nonFiniteResult }
        return value
    }

    private func toRadians(_ value: Double) -> Double {
        angleUnit == .degrees ? value * .pi / 180 : value
    }

    private func fromRadians(_ value: Double) -> Double {
        angleUnit == .degrees ? value * 180 / .pi : value
    }

    private var beginsImplicitFactor: Bool {
        var probe = index
        while probe < characters.count, characters[probe].isWhitespace { probe += 1 }
        guard probe < characters.count else { return false }
        let character = characters[probe]
        return character == "(" || character == "π" || character.isLetter
    }

    private var current: Character? {
        index < characters.count ? characters[index] : nil
    }

    private var isAtEnd: Bool { index >= characters.count }

    private mutating func consume(_ expected: Character) -> Bool {
        skipWhitespace()
        guard current == expected else { return false }
        index += 1
        return true
    }

    private mutating func skipWhitespace() {
        while current?.isWhitespace == true { index += 1 }
    }
}
