import SwiftUI

struct NetworkInfoView: View {
    @State private var model: NetworkInfoViewModel
    @AppStorage(AppPreferenceKey.refreshNetworkInfoOnOpen)
    private var refreshNetworkInfoOnOpen = true

    init(dependencies: AppDependencies) {
        _model = State(initialValue: NetworkInfoViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Network Info",
                    subtitle: "Current network details and the latest snapshot from each device."
                )

                content

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .scrollIndicators(.never)
        .navigationTitle("Network Info")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await model.refresh() }
                } label: {
                    if model.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(model.isRefreshing)
                .help("Refresh Network Info")
            }
        }
        .task {
            model.load()
            if refreshNetworkInfoOnOpen || model.selectedSnapshot == nil {
                await model.refresh()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = model.selectedSnapshot {
            GlassEffectContainer(spacing: ToolPouchLayout.Grid.spacing) {
                VStack(spacing: ToolPouchLayout.Grid.spacing) {
                    NetworkSnapshotCard(snapshot: snapshot)

                    if !model.latestDeviceSnapshots.isEmpty {
                        RecentDevicesCard(
                            snapshots: model.latestDeviceSnapshots,
                            selectedSnapshotID: snapshot.id,
                            onSelect: model.select
                        )
                    }
                }
            }
        } else if model.isRefreshing {
            ProgressView("Reading network information…")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            ContentUnavailableView(
                "No Network Information",
                systemImage: "network.slash",
                description: Text("Refresh to collect the first snapshot for this device.")
            )
        }
    }
}
