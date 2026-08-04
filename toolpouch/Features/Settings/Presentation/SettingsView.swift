import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.refreshNetworkInfoOnOpen)
    private var refreshNetworkInfoOnOpen = true

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
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 180)
        .navigationTitle("Settings")
    }
}
