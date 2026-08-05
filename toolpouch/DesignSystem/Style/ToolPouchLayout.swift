import SwiftUI

enum ToolPouchLayout {
    enum MenuBar {
        static let width: CGFloat = 420
        static let height: CGFloat = 520
        static let footerHeight: CGFloat = 48
    }

    enum Content {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
    }

    enum Grid {
        static let minimumItemWidth: CGFloat = 172
        static let spacing: CGFloat = 10
    }

    enum Tile {
        static let minimumHeight: CGFloat = 86
        static let minimumHeightWithPlatforms: CGFloat = 120
        static let padding: CGFloat = 12
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

extension View {
    func toolPouchIcon(
        _ size: ToolPouchLayout.IconSize,
        weight: Font.Weight = .regular
    ) -> some View {
        font(.system(size: size.rawValue, weight: weight))
    }
}
