import SwiftUI

struct AppTheme: Codable, Identifiable, Hashable, Sendable {
    enum Appearance: String, Codable, Sendable {
        case system
        case light
        case dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    enum RenderingStyle: String, Codable, Sendable {
        case solid
        case glass
    }

    let id: String
    let name: String
    let description: String
    let appearance: Appearance
    let renderingStyle: RenderingStyle
    let colors: AppThemeColors
}

struct AppThemeColors: Codable, Hashable, Sendable {
    let background: ThemeColor
    let surface: ThemeColor
    let elevatedSurface: ThemeColor
    let interactiveSurface: ThemeColor
    let border: ThemeColor
    let primaryText: ThemeColor
    let secondaryText: ThemeColor
    let primaryAccent: ThemeColor
    let secondaryAccent: ThemeColor
    let success: ThemeColor
    let warning: ThemeColor
    let danger: ThemeColor
}

struct ThemeColor: Codable, Hashable, Sendable {
    let hex: String

    var color: Color {
        guard let components else { return .clear }
        return Color(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }

    private var components: (red: Double, green: Double, blue: Double, alpha: Double)? {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard value.count == 6 || value.count == 8,
              let number = UInt64(value, radix: 16) else { return nil }

        if value.count == 8 {
            return (
                Double((number >> 24) & 0xFF) / 255,
                Double((number >> 16) & 0xFF) / 255,
                Double((number >> 8) & 0xFF) / 255,
                Double(number & 0xFF) / 255
            )
        }

        return (
            Double((number >> 16) & 0xFF) / 255,
            Double((number >> 8) & 0xFF) / 255,
            Double(number & 0xFF) / 255,
            1
        )
    }
}

struct AppThemeCatalog: Codable, Sendable {
    let version: Int
    let defaultThemeID: String
    let themes: [AppTheme]
}

extension AppTheme {
    static let draculaFallback = AppTheme(
        id: "dracula",
        name: "Dracula",
        description: "Matte violet surfaces with pink and cyan accents.",
        appearance: .dark,
        renderingStyle: .solid,
        colors: AppThemeColors(
            background: ThemeColor(hex: "282A36"),
            surface: ThemeColor(hex: "343442"),
            elevatedSurface: ThemeColor(hex: "3C3B4D"),
            interactiveSurface: ThemeColor(hex: "494659"),
            border: ThemeColor(hex: "625D73"),
            primaryText: ThemeColor(hex: "F8F8F2"),
            secondaryText: ThemeColor(hex: "B9B5C4"),
            primaryAccent: ThemeColor(hex: "FF79C6"),
            secondaryAccent: ThemeColor(hex: "8BE9FD"),
            success: ThemeColor(hex: "50FA7B"),
            warning: ThemeColor(hex: "F1FA8C"),
            danger: ThemeColor(hex: "FF5555")
        )
    )
}
