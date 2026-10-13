import SwiftUI

/// Standard content column used by built-in tools. It deliberately stays
/// compact in the menu-bar panel and stops growing in wide desktop windows.
struct ToolContentLayout<Content: View>: View {
    @Environment(\.toolPouchPresentationMode) private var presentationMode

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            content
        }
        .frame(
            maxWidth: presentationMode == .expandedWindow
                ? .infinity
                : ToolPouchLayout.Content.maximumReadableWidth,
            alignment: .leading
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(contentPadding)
        .reportToolContentHeight()
    }

    private var contentPadding: CGFloat {
        #if os(watchOS)
        ToolPouchLayout.Spacing.medium
        #else
        ToolPouchLayout.Content.padding
        #endif
    }

    private var contentSpacing: CGFloat {
        #if os(watchOS)
        ToolPouchLayout.Spacing.large
        #else
        ToolPouchLayout.Content.spacing
        #endif
    }
}

/// Reports the natural height of scrollable tool content to the macOS menu-bar
/// shell. The shell uses it to fit short tools without wasting space and caps
/// taller tools to the visible screen, where their existing ScrollView takes over.
struct ToolContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The common card for a logical section of a tool. Feature views supply only
/// their content; padding, surface, border and heading hierarchy stay shared.
struct ToolSectionCard<Content: View>: View {
    private let title: String?
    private let content: Content

    init(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ToolPouchLayout.Spacing.large) {
            if let title {
                Text(title.localizedInterfaceText)
                    .font(ToolPouchLayout.Typography.sectionTitle)
            }
            content
        }
        .padding(ToolPouchLayout.Spacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .toolPouchSurface(elevated: true, cornerRadius: ToolPouchLayout.Radius.card)
    }
}

struct ToolFieldLabel: View {
    let title: String
    let systemImage: String?
    let helpText: String?

    init(
        _ title: String,
        systemImage: String? = nil,
        helpText: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.helpText = helpText
    }

    var body: some View {
        HStack(spacing: ToolPouchLayout.Spacing.xSmall) {
            Group {
                if let systemImage {
                    Label(title.localizedInterfaceText, systemImage: systemImage)
                } else {
                    Text(title.localizedInterfaceText)
                }
            }

            if let helpText {
                ToolHelpButton(text: helpText, diameter: 16)
            }
        }
        .font(ToolPouchLayout.Typography.supporting.weight(.medium))
        .foregroundStyle(.secondary)
    }
}

struct ToolHelpButton: View {
    @Environment(\.appTheme) private var theme
    @State private var isShowingHelp = false

    let text: String
    let diameter: CGFloat

    init(text: String, diameter: CGFloat = 18) {
        self.text = text
        self.diameter = diameter
    }

    var body: some View {
        Button {
            isShowingHelp.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: max(11, diameter - 4), weight: .medium))
                .frame(width: diameter, height: diameter)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.colors.secondaryText.color)
        .help(localizedText)
        .accessibilityLabel(localizedText)
        .popover(isPresented: $isShowingHelp, arrowEdge: .bottom) {
            Text(localizedText)
                .font(ToolPouchLayout.Typography.body)
                .foregroundStyle(theme.colors.primaryText.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 260, alignment: .leading)
                .padding(ToolPouchLayout.Spacing.xLarge)
        }
    }

    private var localizedText: String {
        text.localizedInterfaceText
    }
}

/// A single, recognizable entry point for contextual item actions throughout
/// the app. Supply only actions that make sense for the item (for example New,
/// Edit and Delete); icon sizing, destructive styling and accessibility stay
/// consistent on every platform.
struct ToolPouchMenuAction: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        id = "\(title).\(systemImage)"
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
}

struct ToolPouchActionMenu: View {
    let accessibilityLabel: String
    let actions: [ToolPouchMenuAction]
    var iconSize: ToolPouchLayout.IconSize = .small
    var diameter: CGFloat = 24

    @State private var presentsWatchActions = false

    var body: some View {
#if os(watchOS)
        Button {
            presentsWatchActions = true
        } label: {
            menuIcon
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            accessibilityLabel.localizedInterfaceText,
            isPresented: $presentsWatchActions,
            titleVisibility: .visible
        ) {
            actionButtons
        }
        .accessibilityLabel(accessibilityLabel.localizedInterfaceText)
#else
        Menu {
            actionButtons
        } label: {
            menuIcon
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .fixedSize()
        .help(accessibilityLabel.localizedInterfaceText)
        .accessibilityLabel(accessibilityLabel.localizedInterfaceText)
#endif
    }

    private var menuIcon: some View {
        Image(systemName: "ellipsis")
            .toolPouchIcon(iconSize, weight: .semibold)
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .toolPouchCircleSurface()
    }

    @ViewBuilder
    private var actionButtons: some View {
        ForEach(Array(actions.enumerated()), id: \.offset) { _, item in
            Button(role: item.role, action: item.action) {
                Label(item.title.localizedInterfaceText, systemImage: item.systemImage)
            }
        }
    }
}

/// Shared segmented selector used instead of the native prominent tint. The
/// selected segment follows the same dark-accent treatment as primary buttons.
struct ToolPouchSegmentedControl<Option: Hashable>: View {
    @Environment(\.appTheme) private var theme

    private let options: [Option]
    @Binding private var selection: Option
    private let title: (Option) -> String

    init(
        _ options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String
    ) {
        self.options = options
        _selection = selection
        self.title = title
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(title(option).localizedInterfaceText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(
                    ToolPouchSegmentButtonStyle(isSelected: selection == option)
                )
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(3)
        .background(
            theme.colors.recessedSurface.color,
            in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
                .stroke(theme.colors.border.color.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct ToolPouchAccentButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToolPouchLayout.Typography.body.weight(.semibold))
            .foregroundStyle(theme.colors.primaryAccent.color)
            .padding(.horizontal, ToolPouchLayout.Control.horizontalPadding + 2)
            .frame(minHeight: ToolPouchLayout.Control.compactHeight)
            .background(
                theme.colors.accentButtonBackground.color.opacity(
                    configuration.isPressed ? 0.78 : 1
                ),
                in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control)
                    .stroke(theme.colors.primaryAccent.color.opacity(0.22), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(.rect)
    }
}

private struct ToolPouchSegmentButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToolPouchLayout.Typography.body.weight(.medium))
            .foregroundStyle(
                isSelected
                    ? theme.colors.primaryAccent.color
                    : theme.colors.primaryText.color
            )
            .padding(.horizontal, ToolPouchLayout.Control.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: ToolPouchLayout.Control.compactHeight)
            .background(
                isSelected
                    ? theme.colors.accentButtonBackground.color
                    : theme.colors.panelSurface.color.opacity(
                        configuration.isPressed ? 0.65 : 0
                    ),
                in: RoundedRectangle(cornerRadius: ToolPouchLayout.Radius.control - 2)
            )
            .contentShape(.rect)
    }
}

extension View {
    func reportToolContentHeight(additionalHeight: CGFloat = 0) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ToolContentHeightPreferenceKey.self,
                    value: geometry.size.height + additionalHeight
                )
            }
        }
    }

    /// Shared field/picker surface. Applying this modifier instead of a native
    /// rounded-border field keeps controls identical across feature screens.
    func toolPouchControlSurface(
        minimumHeight: CGFloat = ToolPouchLayout.Control.regularHeight,
        horizontalPadding: CGFloat = ToolPouchLayout.Control.horizontalPadding
    ) -> some View {
        frame(minHeight: minimumHeight)
            .padding(.horizontal, horizontalPadding)
            .toolPouchSurface(
                interactive: true,
                cornerRadius: ToolPouchLayout.Radius.control
            )
    }

    /// Multiline and read-only value surface. Using one modifier avoids the
    /// slightly different gray boxes that individual tools used previously.
    func toolPouchEditorSurface(
        minimumHeight: CGFloat,
        maximumHeight: CGFloat = ToolPouchLayout.Editor.maximumHeight
    ) -> some View {
        modifier(
            ToolPouchEditorSurfaceModifier(
                minimumHeight: minimumHeight,
                maximumHeight: maximumHeight
            )
        )
    }

    func toolPouchPrimaryAction() -> some View {
        buttonStyle(ToolPouchAccentButtonStyle())
            .controlSize(.small)
            .frame(minHeight: ToolPouchLayout.Control.compactHeight)
    }

    func toolPouchSecondaryAction() -> some View {
        buttonStyle(.glass)
            .controlSize(.small)
            .frame(minHeight: ToolPouchLayout.Control.compactHeight)
    }
}

private struct ToolPouchEditorSurfaceModifier: ViewModifier {
    @Environment(\.toolPouchPresentationMode) private var presentationMode

    let minimumHeight: CGFloat
    let maximumHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .padding(ToolPouchLayout.Spacing.medium)
            .frame(
                minHeight: minimumHeight,
                idealHeight: resolvedIdealHeight,
                maxHeight: resolvedMaximumHeight
            )
            .clipped()
            .toolPouchSurface(
                interactive: true,
                cornerRadius: ToolPouchLayout.Radius.control
            )
    }

    private var resolvedIdealHeight: CGFloat {
        presentationMode == .expandedWindow
            ? max(minimumHeight, ToolPouchLayout.Editor.expandedIdealHeight)
            : minimumHeight
    }

    private var resolvedMaximumHeight: CGFloat {
        presentationMode == .expandedWindow
            ? max(maximumHeight, ToolPouchLayout.Editor.expandedMaximumHeight)
            : maximumHeight
    }
}
