import SwiftUI
#if !os(watchOS)
import UniformTypeIdentifiers
#endif

struct DomainLookupView: View {
    @State private var model: DomainLookupViewModel

    init(service: any DomainLookupService) {
        _model = State(initialValue: DomainLookupViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToolPouchLayout.Content.spacing) {
                ScreenHeader(
                    title: "Whois",
                    subtitle: "Check public registration details for a domain."
                )
                searchPanel
                content
            }
            .padding(ToolPouchLayout.Content.padding)
        }
        .scrollIndicators(.never)
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            domainTextField

            lookupButton
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var domainTextField: some View {
        #if os(macOS)
        TextField("example.com", text: $model.query)
        #else
        TextField("example.com", text: $model.query)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit(lookup)
        #endif
    }

    @ViewBuilder
    private var lookupButton: some View {
        #if os(macOS)
        lookupButtonBase
            .keyboardShortcut(.defaultAction)
        #else
        lookupButtonBase
        #endif
    }

    private var lookupButtonBase: some View {
        Button(action: lookup) {
            HStack {
                if model.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "magnifyingglass")
                        .toolPouchIcon(.small)
                }
                Text(model.isLoading ? "Looking Up…" : "Look Up Domain")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .disabled(!model.canLookup)
    }

    @ViewBuilder
    private var content: some View {
        if let registration = model.registration {
            DomainRegistrationView(registration: registration)
        } else if let errorMessage = model.errorMessage {
            ContentUnavailableView {
                Label("Lookup Failed", systemImage: "exclamationmark.magnifyingglass")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again", action: lookup)
            }
            .frame(maxWidth: .infinity, minHeight: 190)
        } else {
            ContentUnavailableView {
                Label("Enter a Domain", systemImage: "globe")
            } description: {
                Text("Registration dates, registrar, nameservers, DNSSEC, and domain statuses will appear here.")
            }
            .frame(maxWidth: .infinity, minHeight: 190)
        }
    }

    private func lookup() {
        Task { await model.lookup() }
    }
}

private struct DomainRegistrationView: View {
    let registration: DomainRegistration
    #if !os(watchOS)
    @State private var isExportingResponse = false
    @State private var exportErrorMessage: String?
    @State private var isShowingExportError = false
    #endif

    var body: some View {
        VStack(spacing: 12) {
            overviewCard
            registrationCard
            nameserverCard
            statusCard
            noticesCard
            #if !os(watchOS)
            rawResponseCard
            #endif
        }
        #if !os(watchOS)
        #if !os(macOS)
        .fileExporter(
            isPresented: $isExportingResponse,
            document: RDAPJSONDocument(content: registration.rawResponse),
            contentType: .json,
            defaultFilename: "\(registration.name.lowercased())-rdap"
        ) { result in
            if case let .failure(error) = result {
                exportErrorMessage = error.localizedDescription
                isShowingExportError = true
            }
        }
        #endif
        .alert("Unable to Save Response", isPresented: $isShowingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "The RDAP response could not be saved.")
        }
        #endif
    }

    private var overviewCard: some View {
        DomainLookupCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe")
                    .toolPouchIcon(.large)

                VStack(alignment: .leading, spacing: 4) {
                    Text(registration.unicodeName ?? registration.name)
                        .font(.title3.bold())
                        .selectableText()
                    if let unicodeName = registration.unicodeName,
                       unicodeName.caseInsensitiveCompare(registration.name) != .orderedSame {
                        Text(registration.name)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                #if !os(watchOS)
                CopyButton(value: registration.name)
                #endif
            }

            Divider()

            DomainInfoRow(
                title: "DNSSEC",
                value: dnssecTitle,
                systemImage: registration.isDNSSECSigned == true
                    ? "checkmark.shield"
                    : "shield.slash"
            )
        }
    }

    private var registrationCard: some View {
        DomainLookupCard(title: "Registration") {
            if let registrarName = registration.registrarName {
                DomainInfoRow(title: "Registrar", value: registrarName, systemImage: "building.columns")
            }
            if let registeredAt = registration.registeredAt {
                DomainInfoRow(title: "Registered", value: format(registeredAt), systemImage: "calendar.badge.plus")
            }
            if let expiresAt = registration.expiresAt {
                DomainInfoRow(title: "Expires", value: format(expiresAt), systemImage: "calendar.badge.clock")
            }
            if let lastChangedAt = registration.lastChangedAt {
                DomainInfoRow(title: "Last Changed", value: format(lastChangedAt), systemImage: "clock.arrow.circlepath")
            }
            if let handle = registration.registryHandle {
                DomainInfoRow(title: "Registry Handle", value: handle, systemImage: "number")
            }
        }
    }

    @ViewBuilder
    private var nameserverCard: some View {
        if !registration.nameservers.isEmpty {
            DomainLookupCard(title: "Nameservers") {
                ForEach(registration.nameservers, id: \.self) { nameserver in
                    DomainInfoRow(title: "DNS", value: nameserver, systemImage: "server.rack")
                }
            }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        if !registration.statuses.isEmpty {
            DomainLookupCard(title: "Statuses") {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), alignment: .leading)],
                    alignment: .leading,
                    spacing: 7
                ) {
                    ForEach(registration.statuses, id: \.self) { status in
                        Text(status.replacingOccurrences(of: "_", with: " "))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.quaternary, in: .capsule)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noticesCard: some View {
        if !registration.notices.isEmpty {
            DomainLookupCard(title: "Registry Notes") {
                ForEach(Array(registration.notices.enumerated()), id: \.offset) { _, notice in
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    #if !os(watchOS)
    private var rawResponseCard: some View {
        DomainLookupCard {
            HStack(alignment: .top, spacing: 10) {
                DisclosureGroup("Raw RDAP Response") {
                    ScrollView([.horizontal, .vertical]) {
                        Text(registration.rawResponse)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .fixedSize(horizontal: true, vertical: true)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 300)
                    .scrollIndicators(.visible)
                }

                Button {
                    #if os(macOS)
                    saveResponse()
                    #else
                    isExportingResponse = true
                    #endif
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .toolPouchIcon(.medium, weight: .medium)
                }
                .buttonStyle(.borderless)
                .help("Save RDAP Response as JSON")
                .accessibilityLabel("Save RDAP Response as JSON")
            }
        }
    }
    #endif

    private var dnssecTitle: String {
        switch registration.isDNSSECSigned {
        case true: "Signed"
        case false: "Not Signed"
        case nil: "Not Reported"
        }
    }

    private func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    #if os(macOS)
    private func saveResponse() {
        guard let url = CenteredFilePanel.chooseSaveURL(
            title: "Save RDAP Response",
            allowedContentTypes: [.json],
            suggestedFilename: "\(registration.name.lowercased())-rdap.json"
        ) else { return }

        do {
            try Data(registration.rawResponse.utf8).write(to: url, options: .atomic)
        } catch {
            exportErrorMessage = error.localizedDescription
            isShowingExportError = true
        }
    }
    #endif
}

#if !os(watchOS)
private struct RDAPJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            content = ""
            return
        }
        content = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}
#endif

private struct DomainLookupCard<Content: View>: View {
    private let title: String?
    private let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct DomainInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .toolPouchIcon(.small)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .selectableText()
            }

            Spacer(minLength: 8)

            #if !os(watchOS)
            CopyButton(value: value)
            #endif
        }
    }
}

private extension View {
    @ViewBuilder
    func selectableText() -> some View {
        #if os(watchOS)
        self
        #else
        textSelection(.enabled)
        #endif
    }
}
