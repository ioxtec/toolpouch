import SwiftUI

enum ToolPouchLayout {
    enum MenuBar {
        static let width: CGFloat = 380
        static let height: CGFloat = 490
        static let footerHeight: CGFloat = 40
        static let contentPadding: CGFloat = 10
        static let contentSpacing: CGFloat = 10
        static let gridSpacing: CGFloat = 8
    }

    enum Content {
        static let padding: CGFloat = 12
        static let spacing: CGFloat = 12
    }

    enum Grid {
        static let minimumItemWidth: CGFloat = 160
        static let spacing: CGFloat = 8
    }

    enum Tile {
        static let minimumHeight: CGFloat = 72
        static let minimumHeightWithPlatforms: CGFloat = 100
        static let padding: CGFloat = 10
        static let cornerRadius: CGFloat = 12
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
