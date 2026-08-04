import CoreGraphics

enum ToolPouchLayout {
    enum MenuBar {
        static let width: CGFloat = 420
        static let height: CGFloat = 520
    }

    enum Content {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 20
    }

    enum Grid {
        static let minimumItemWidth: CGFloat = 172
        static let spacing: CGFloat = 12
    }

    enum Tile {
        static let minimumHeight: CGFloat = 112
        static let padding: CGFloat = 14
        static let cornerRadius: CGFloat = 12
    }
}
