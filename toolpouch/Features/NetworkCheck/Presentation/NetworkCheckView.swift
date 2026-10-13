import SwiftUI

struct NetworkCheckView: View {
    private struct CommonPort: Identifiable {
        let port: Int
        let name: String
        var id: Int { port }
    }

    private static let commonPorts = [
        CommonPort(port: 22, name: "SSH"),
        CommonPort(port: 53, name: "DNS"),
        CommonPort(port: 80, name: "HTTP"),
        CommonPort(port: 443, name: "HTTPS"),
        CommonPort(port: 3_389, name: "RDP"),
    ]

    private let checker: any NetworkChecking

    @State private var host = ""
    @State private var port = 443
    @State private var result: NetworkCheckResult?
    @State private var errorMessage: String?
    @State private var isChecking = false

    init(checker: any NetworkChecking) {
        self.checker = checker
    }

    var body: some View {
        ScrollView {
            ToolContentLayout {
                ScreenHeader(
                    title: "Network Check",
                    subtitle: "Resolve a host and test a TCP port without using a website."
                )
                inputPanel
                if isChecking || result != nil || errorMessage != nil {
                    resultPanel
                }
            }
        }
        .scrollIndicators(.never)
    }

    private var inputPanel: some View {
        ToolSectionCard("Destination") {
            ToolFieldLabel("Host", systemImage: "network")

            TextField("example.com or 192.168.1.1", text: $host)
                .textFieldStyle(.plain)
                .toolPouchControlSurface()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                #endif

            HStack(spacing: ToolPouchLayout.Spacing.medium) {
                ToolFieldLabel("Port")
                TextField("Port", value: $port, format: .number.grouping(.never))
                    .textFieldStyle(.plain)
                    .toolPouchControlSurface()
                    .frame(width: 84)
                Spacer()
                Button {
                    Task { await performCheck() }
                } label: {
                    if isChecking {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Check", systemImage: "play.fill")
                    }
                }
                .toolPouchPrimaryAction()
                .disabled(isChecking || host.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ToolPouchLayout.Spacing.small) {
                    ForEach(Self.commonPorts) { item in
                        Button("\(item.name) · \(item.port)") {
                            port = item.port
                        }
                        .toolPouchSecondaryAction()
                        .tint(port == item.port ? .accentColor : nil)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultPanel: some View {
        ToolSectionCard("Result") {
            if isChecking {
                Label("Resolving host and checking the connection…", systemImage: "network")
                    .foregroundStyle(.secondary)
            } else if let errorMessage {
                Label(errorMessage, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            } else if let result {
                addressRows(result)
                Divider()
                portRow(result)
                Text("Checked locally at \(result.checkedAt.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addressRows(_ result: NetworkCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("DNS resolved", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

            ForEach(result.addresses, id: \.self) { address in
                HStack {
                    Text(address)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Spacer()
                    CopyButton(value: address)
                }
            }
        }
    }

    @ViewBuilder
    private func portRow(_ result: NetworkCheckResult) -> some View {
        switch result.portStatus {
        case let .reachable(latency):
            HStack {
                Label("Port \(result.request.port) is reachable", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text("\(latency) ms")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        case let .unreachable(reason):
            VStack(alignment: .leading, spacing: 4) {
                Label("Port \(result.request.port) is not reachable", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func performCheck() async {
        isChecking = true
        result = nil
        errorMessage = nil
        defer { isChecking = false }

        do {
            let request = try NetworkCheckRequest(host: host, port: port)
            result = try await checker.check(request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
