import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.refreshNetworkInfoOnOpen)
    private var refreshNetworkInfoOnOpen = true
    #if os(macOS)
    @State private var screenCapturePermission = ScreenCapturePermissionManager.shared
    #endif

    var body: some View {
        Form {
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
        .frame(width: 520, height: 330)
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
}
