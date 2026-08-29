import SwiftUI

struct ToolPouchCircleButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let help: String
    let isEnabled: Bool
    let diameter: CGFloat
    let iconSize: ToolPouchLayout.IconSize
    let iconWeight: Font.Weight
    let action: () -> Void

    init(
        systemImage: String,
        accessibilityLabel: String,
        help: String? = nil,
        isEnabled: Bool = true,
        diameter: CGFloat = 36,
        iconSize: ToolPouchLayout.IconSize = .medium,
        iconWeight: Font.Weight = .semibold,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.help = help ?? accessibilityLabel
        self.isEnabled = isEnabled
        self.diameter = diameter
        self.iconSize = iconSize
        self.iconWeight = iconWeight
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.clear)

                Image(systemName: systemImage)
                    .toolPouchIcon(iconSize, weight: iconWeight)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .toolPouchCircleSurface()
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
        .help(help)
        .accessibilityLabel(accessibilityLabel)
    }
}
