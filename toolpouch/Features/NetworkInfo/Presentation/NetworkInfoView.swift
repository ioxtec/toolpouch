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
                NetworkInfoHeader(
                    isRefreshing: model.isRefreshing,
                    refresh: refresh
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

    private func refresh() {
        Task { await model.refresh() }
    }
}
