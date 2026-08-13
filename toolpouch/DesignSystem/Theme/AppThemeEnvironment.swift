import SwiftUI

private struct AppThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.draculaFallback
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeEnvironmentKey.self] }
        set { self[AppThemeEnvironmentKey.self] = newValue }
    }
}

extension View {
    func toolPouchTheme(_ store: AppThemeStore) -> some View {
        modifier(AppThemeRootModifier(store: store))
    }

    func toolPouchSurface(
        elevated: Bool = false,
        interactive: Bool = false,
        cornerRadius: CGFloat = ToolPouchLayout.Tile.cornerRadius
    ) -> some View {
        modifier(
            AppThemeSurfaceModifier(
                elevated: elevated,
                interactive: interactive,
                cornerRadius: cornerRadius
            )
        )
    }

    func toolPouchCircleSurface(interactive: Bool = true) -> some View {
        modifier(AppThemeCircleSurfaceModifier(interactive: interactive))
    }
}

private struct AppThemeRootModifier: ViewModifier {
    @ObservedObject var store: AppThemeStore

    func body(content: Content) -> some View {
        let theme = store.selectedTheme

        content
            .environment(\.appTheme, theme)
            .preferredColorScheme(theme.appearance.colorScheme)
            .tint(theme.colors.primaryAccent.color)
            .foregroundStyle(theme.colors.primaryText.color)
            .background(theme.colors.background.color.ignoresSafeArea())
    }
}

private struct AppThemeSurfaceModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    let elevated: Bool
    let interactive: Bool
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme.renderingStyle == .glass {
            content.glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .rect(
                    corners: .concentric(minimum: .fixed(cornerRadius)),
                    isUniform: true
                )
            )
        } else {
            content
                .background(surfaceColor, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.colors.border.color.opacity(0.72), lineWidth: 1)
                }
        }
    }

    private var surfaceColor: Color {
        if interactive { return theme.colors.interactiveSurface.color }
        if elevated { return theme.colors.elevatedSurface.color }
        return theme.colors.surface.color
    }
}

private struct AppThemeCircleSurfaceModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme.renderingStyle == .glass {
            content.glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .circle
            )
        } else {
            content
                .background(theme.colors.interactiveSurface.color, in: .circle)
                .overlay {
                    Circle()
                        .stroke(theme.colors.border.color.opacity(0.72), lineWidth: 1)
                }
        }
    }
}
