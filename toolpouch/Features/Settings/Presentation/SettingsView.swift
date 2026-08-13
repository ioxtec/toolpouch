import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var themeStore: AppThemeStore
    @AppStorage(AppPreferenceKey.refreshNetworkInfoOnOpen)
    private var refreshNetworkInfoOnOpen = true
    #if os(macOS)
    @State private var screenCapturePermission = ScreenCapturePermissionManager.shared
    #endif

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: themeSelection) {
                    ForEach(themeStore.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }

                Text(themeStore.selectedTheme.description)
                    .font(.caption)
                    .foregroundStyle(themeStore.selectedTheme.colors.secondaryText.color)

                ThemeSwatches(theme: themeStore.selectedTheme)
            }

            Section("Network Info") {
                Toggle(
                    "Refresh automatically when opened",
                    isOn: $refreshNetworkInfoOnOpen
                )

                Text("When disabled, Network Info shows the latest saved snapshot until you refresh it manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            #if os(macOS)
            Section("Permissions") {
                HStack {
                    Label(
                        "Screen Recording",
                        systemImage: "rectangle.dashed.badge.record"
                    )
                    Spacer()
                    Text(screenCapturePermission.isGranted ? "Allowed" : "Needs Access")
                        .foregroundStyle(
                            screenCapturePermission.isGranted ? Color.green : Color.orange
                        )
                }

                Text("Color Picker reads a small area around the pointer only while picking a color.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !screenCapturePermission.isGranted {
                    Text("After granting access, reopen ToolPouch so macOS can apply the permission to the running app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Request Access") {
                        screenCapturePermission.requestAccess()
                    }
                    .disabled(screenCapturePermission.isGranted)

                    Button("Open System Settings") {
                        screenCapturePermission.openSystemSettings()
                    }

                    Button("Refresh Status") {
                        screenCapturePermission.refresh()
                    }
                }
            }
            #endif
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 460)
        .navigationTitle("Settings")
        #if os(macOS)
        .onAppear { screenCapturePermission.refresh() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            screenCapturePermission.refresh()
        }
        #endif
    }

    private var themeSelection: Binding<String> {
        Binding(
            get: { themeStore.selectedThemeID },
            set: { themeStore.selectTheme(id: $0) }
        )
    }
}

private struct ThemeSwatches: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 7) {
            swatch(theme.colors.background.color)
            swatch(theme.colors.surface.color)
            swatch(theme.colors.interactiveSurface.color)
            swatch(theme.colors.primaryAccent.color)
            swatch(theme.colors.secondaryAccent.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Theme color preview")
    }

    private func swatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 18, height: 18)
            .overlay {
                Circle().stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }
}
