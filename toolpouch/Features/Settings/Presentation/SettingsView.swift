import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var themeStore: AppThemeStore
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            AppearanceSettingsView(
                themeStore: themeStore,
                languageStore: languageStore
            )
            .tabItem { Label("Appearance", systemImage: "paintbrush") }

            #if os(macOS)
            PermissionsSettingsView()
                .tabItem { Label("Permissions", systemImage: "hand.raised") }
            #endif

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(minWidth: 600, idealWidth: 680, minHeight: 380, idealHeight: 460)
        .navigationTitle("Settings")
    }
}

private struct GeneralSettingsView: View {
    @AppStorage(AppPreferenceKey.refreshNetworkInfoOnOpen)
    private var refreshNetworkInfoOnOpen = true
    @AppStorage(AppPreferenceKey.systemStatsHistoryDuration)
    private var systemStatsHistoryDuration = SystemStatsHistoryDuration.defaultValue.rawValue

    var body: some View {
        Form {
            Section("Network Info") {
                Toggle("Refresh automatically when opened", isOn: $refreshNetworkInfoOnOpen)
                Text("When disabled, Network Info shows the latest saved snapshot until you refresh it manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("System Stats") {
                Picker("Keep chart history", selection: $systemStatsHistoryDuration) {
                    ForEach(SystemStatsHistoryDuration.allCases) { duration in
                        Text(duration.title.localizedInterfaceText).tag(duration.rawValue)
                    }
                }
                Text("Samples are stored locally on this device. iPhone and Apple Watch collection pauses whenever the system suspends the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AppearanceSettingsView: View {
    @ObservedObject var themeStore: AppThemeStore
    @ObservedObject var languageStore: AppLanguageStore

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Language", selection: languageSelection) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(verbatim: language.displayName).tag(language)
                    }
                }

                Picker("Theme", selection: themeSelection) {
                    ForEach(themeStore.themes) { theme in
                        Text(theme.name.localizedInterfaceText).tag(theme.id)
                    }
                }

                Text(themeStore.selectedTheme.description.localizedInterfaceText)
                    .font(.caption)
                    .foregroundStyle(themeStore.selectedTheme.colors.secondaryText.color)

                ThemeSwatches(theme: themeStore.selectedTheme)
            }
        }
        .formStyle(.grouped)
    }

    private var themeSelection: Binding<String> {
        Binding(get: { themeStore.selectedThemeID }, set: themeStore.selectTheme)
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(get: { languageStore.selection }, set: languageStore.select)
    }
}

#if os(macOS)
private struct PermissionsSettingsView: View {
    @State private var screenCapturePermission = ScreenCapturePermissionManager.shared

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    Label("Screen Recording", systemImage: "rectangle.dashed.badge.record")
                    Spacer()
                    Text((screenCapturePermission.isGranted ? "Allowed" : "Needs Access").localizedInterfaceText)
                        .foregroundStyle(screenCapturePermission.isGranted ? Color.green : Color.orange)
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
                    Button("Request Access") { screenCapturePermission.requestAccess() }
                        .disabled(screenCapturePermission.isGranted)
                    Button("Open System Settings") { screenCapturePermission.openSystemSettings() }
                    Button("Refresh Status") { screenCapturePermission.refresh() }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { screenCapturePermission.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            screenCapturePermission.refresh()
        }
    }
}
#endif

private struct AboutSettingsView: View {
    private let appVersion = AppVersionInfo.current
    private let links = ApplicationLinks.current

    var body: some View {
        Form {
            Section("About") {
                LabeledContent("Version", value: appVersion.version)
                LabeledContent("Build", value: appVersion.build)

                if let url = links.privacyPolicy {
                    Link("Privacy Policy", destination: url)
                }
                if let url = links.support {
                    Link("Help and Support", destination: url)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ThemeSwatches: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 7) {
            swatch(theme.colors.background.color)
            swatch(theme.colors.recessedSurface.color)
            swatch(theme.colors.panelSurface.color)
            swatch(theme.colors.accentButtonBackground.color)
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
