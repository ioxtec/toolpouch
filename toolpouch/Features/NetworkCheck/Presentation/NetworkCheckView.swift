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
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Network Check",
                    subtitle: "Resolve a host and test a TCP port without using a website."
                )
                inputPanel
                if isChecking || result != nil || errorMessage != nil {
                    resultPanel
                }
            }
            .padding(ToolPouchLayout.Content.padding)
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Destination")
                .font(.headline)

            TextField("example.com or 192.168.1.1", text: $host)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                #endif

            HStack {
                Text("Port")
                    .foregroundStyle(.secondary)
                TextField("Port", value: $port, format: .number.grouping(.never))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 92)
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
                .buttonStyle(.borderedProminent)
                .disabled(isChecking || host.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.commonPorts) { item in
                        Button("\(item.name) · \(item.port)") {
                            port = item.port
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(port == item.port ? .accentColor : nil)
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Result")
                .font(.headline)

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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
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
