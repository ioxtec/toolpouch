import SwiftUI

struct AppNavigationBar: View {
    @Environment(\.appTheme) private var theme

    let canGoBack: Bool
    let isAtHome: Bool
    let goBack: () -> Void
    let goHome: () -> Void
    let close: (() -> Void)?
    let density: ToolPouchContentDensity

    init(
        canGoBack: Bool,
        isAtHome: Bool,
        goBack: @escaping () -> Void,
        goHome: @escaping () -> Void,
        close: (() -> Void)? = nil,
        density: ToolPouchContentDensity = .regular
    ) {
        self.canGoBack = canGoBack
        self.isAtHome = isAtHome
        self.goBack = goBack
        self.goHome = goHome
        self.close = close
        self.density = density
    }

    var body: some View {
        ZStack {
            brand

            HStack(spacing: 6) {
                ToolPouchCircleButton(
                    systemImage: "chevron.left",
                    accessibilityLabel: "Back",
                    isEnabled: canGoBack,
                    diameter: navigationButtonDiameter,
                    action: goBack
                )

                ToolPouchCircleButton(
                    systemImage: "house",
                    accessibilityLabel: "All Sections",
                    isEnabled: !isAtHome,
                    diameter: navigationButtonDiameter,
                    action: goHome
                )

                Spacer()

                if let close {
                    ToolPouchCircleButton(
                        systemImage: "xmark",
                        accessibilityLabel: "Close ToolPouch",
                        diameter: navigationButtonDiameter,
                        iconSize: .small,
                        iconWeight: .bold,
                        action: close
                    )
                }
            }
        }
        .padding(.horizontal, density == .compact ? 10 : 12)
        .frame(
            height: density == .compact
                ? 46
                : ToolPouchLayout.Navigation.height
        )
    }

    private var brand: some View {
        Text("Tool Pouch")
            .font(wordmarkFont)
            .tracking(0.7)
            .foregroundStyle(theme.colors.primaryText.color)
            .overlay {
                stitchPattern
                    .mask {
                        Text("Tool Pouch")
                            .font(wordmarkFont)
                            .tracking(0.7)
                    }
            }
            .accessibilityLabel("Tool Pouch")
    }

    private var wordmarkFont: Font {
        .custom(
            "AmericanTypewriter-Bold",
            fixedSize: density == .compact ? 20 : 22
        )
    }

    private var stitchPattern: some View {
        Canvas { context, size in
            var stitches = Path()
            let middleY = size.height * 0.55

            for x in stride(from: -2.0, through: size.width + 2, by: 6) {
                stitches.move(to: CGPoint(x: x, y: middleY + 1.5))
                stitches.addLine(to: CGPoint(x: x + 3, y: middleY - 1.5))
            }

            context.stroke(
                stitches,
                with: .color(theme.colors.primaryAccent.color.opacity(0.95)),
                style: StrokeStyle(lineWidth: 1.25, lineCap: .round)
            )
        }
        .allowsHitTesting(false)
    }

    private var navigationButtonDiameter: CGFloat {
        density == .compact ? 34 : 36
    }
}
