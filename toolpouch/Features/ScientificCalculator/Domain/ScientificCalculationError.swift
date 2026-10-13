import Foundation

nonisolated enum ScientificCalculationError: Error, Equatable, LocalizedError {
    case emptyExpression
    case unexpectedCharacter(Character)
    case unexpectedToken
    case missingClosingParenthesis
    case unknownSymbol(String)
    case unknownFunction(String)
    case divisionByZero
    case domainError
    case nonFiniteResult
    case expressionTooComplex

    var errorDescription: String? {
        switch self {
        case .expressionTooComplex:
            "The expression is too long or deeply nested. Simplify it and try again.".localizedInterfaceText
        case .emptyExpression:
            "Enter an expression to calculate.".localizedInterfaceText
        case let .unexpectedCharacter(character):
            String(
                format: "Unexpected character: %@".localizedInterfaceText,
                String(character)
            )
        case .unexpectedToken:
            "The expression is incomplete or invalid.".localizedInterfaceText
        case .missingClosingParenthesis:
            "A closing parenthesis is missing.".localizedInterfaceText
        case let .unknownSymbol(symbol):
            String(
                format: "Unknown symbol: %@".localizedInterfaceText,
                symbol
            )
        case let .unknownFunction(function):
            String(
                format: "Unknown function: %@".localizedInterfaceText,
                function
            )
        case .divisionByZero:
            "Division by zero is undefined.".localizedInterfaceText
        case .domainError:
            "The value is outside this function’s domain.".localizedInterfaceText
        case .nonFiniteResult:
            "The result is too large to display.".localizedInterfaceText
        }
    }
}
