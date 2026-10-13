import SwiftUI

enum ToolPouchLayout {
    /// Shared geometry for every built-in tool. Keep layout decisions here so
    /// the menu-bar panel, iPhone and full-size windows grow at the same pace.
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 10
        static let xLarge: CGFloat = 12
    }

    enum Radius {
        static let control: CGFloat = 8
        static let card: CGFloat = 12
    }

    enum Control {
        static let compactHeight: CGFloat = 28
        static let regularHeight: CGFloat = 32
        static let horizontalPadding: CGFloat = 10
    }

    enum Editor {
        /// Multiline fields grow with their content only up to this height.
        /// Beyond it, TextEditor and read-only result views scroll internally.
        static let maximumHeight: CGFloat = 240
        static let expandedIdealHeight: CGFloat = 280
        static let expandedMaximumHeight: CGFloat = 560
    }

    enum Typography {
        static let screenTitle = Font.headline
        static let sectionTitle = Font.subheadline.weight(.semibold)
        static let body = Font.subheadline
        static let supporting = Font.caption
        static let compactSupporting = Font.caption2
        static let value = Font.body.monospacedDigit()
    }

    enum MenuBar {
        static let width: CGFloat = 380
        static let height: CGFloat = 490
        static let minimumHeight: CGFloat = 300
        static let screenMargin: CGFloat = 48
        /// Navigation, search, divider and footer surrounding the tool content.
        static let chromeHeight: CGFloat = 137
        static let footerHeight: CGFloat = 48
        static let contentPadding: CGFloat = 10
        static let contentSpacing: CGFloat = 10
        static let gridSpacing: CGFloat = 8
    }

    enum Content {
        static let padding: CGFloat = 12
        static let spacing: CGFloat = Spacing.xLarge
        static let maximumReadableWidth: CGFloat = 720
    }

    enum Grid {
        static let minimumItemWidth: CGFloat = 160
        static let spacing: CGFloat = 8
    }

    enum Tile {
        /// Compact dashboard/category rows intentionally fit more navigation
        /// choices without sacrificing a readable title and description.
        static let compactMinimumHeight: CGFloat = 44
        static let compactIconDiameter: CGFloat = 28
        static let compactPadding: CGFloat = 6
        static let minimumHeight: CGFloat = 72
        static let minimumHeightWithPlatforms: CGFloat = 100
        static let padding: CGFloat = 10
        static let cornerRadius: CGFloat = Radius.card
    }

    enum Navigation {
        static let height: CGFloat = 42
    }

    enum IconSize: CGFloat {
        case small = 13
        case medium = 17
        case large = 22
    }
}

enum ToolPouchPresentationMode {
    case compactPanel
    case standard
    case expandedWindow
}

private struct ToolPouchPresentationModeKey: EnvironmentKey {
    static let defaultValue = ToolPouchPresentationMode.standard
}

extension EnvironmentValues {
    var toolPouchPresentationMode: ToolPouchPresentationMode {
        get { self[ToolPouchPresentationModeKey.self] }
        set { self[ToolPouchPresentationModeKey.self] = newValue }
    }
}

enum ToolPouchContentDensity {
    case regular
    case compact
}

extension View {
    func toolPouchIcon(
        _ size: ToolPouchLayout.IconSize,
        weight: Font.Weight = .regular
    ) -> some View {
        font(.system(size: size.rawValue, weight: weight))
    }
}
