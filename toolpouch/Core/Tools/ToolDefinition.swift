nonisolated struct ToolDefinition: Hashable, Identifiable, Sendable {
    /// A stable, globally unique identifier for a tool.
    ///
    /// Reverse-DNS values stay stable across catalog changes and app releases.
    struct ID: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        var description: String {
            rawValue
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    let id: ID
    let categoryID: ToolCategory.ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>
    let executionBackend: ToolExecutionBackend
    /// Capabilities the device must expose for this tool to be available.
    /// Defaults to an empty set (available wherever the platform matches).
    let requiredCapabilities: Set<ToolCapability>

    init(
        id: ID,
        categoryID: ToolCategory.ID,
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>,
        executionBackend: ToolExecutionBackend,
        requiredCapabilities: Set<ToolCapability> = []
    ) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
        self.executionBackend = executionBackend
        self.requiredCapabilities = requiredCapabilities
    }
}

extension ToolDefinition.ID {
    static let unitConverter = Self(rawValue: "com.toolpouch.unit-converter")
    static let quickCopyNotes = Self(rawValue: "com.toolpouch.quick-copy-notes")
    static let networkInfo = Self(rawValue: "com.toolpouch.network-info")
    static let wiFiScanner = Self(rawValue: "com.toolpouch.wifi-scanner")
    static let sshKeys = Self(rawValue: "com.toolpouch.ssh-keys")
    static let passwordGenerator = Self(rawValue: "com.toolpouch.password-generator")
    static let textEncoder = Self(rawValue: "com.toolpouch.text-encoder")
    static let jsonToolkit = Self(rawValue: "com.toolpouch.json-toolkit")
    static let hashChecksum = Self(rawValue: "com.toolpouch.hash-checksum")
    static let networkCheck = Self(rawValue: "com.toolpouch.network-check")
    static let clipboardInspector = Self(rawValue: "com.toolpouch.clipboard-inspector")
    static let domainLookup = Self(rawValue: "com.toolpouch.domain-lookup")
    static let imageInspector = Self(rawValue: "com.toolpouch.image-inspector")
    static let colorPicker = Self(rawValue: "com.toolpouch.color-picker")
    static let archiveTool = Self(rawValue: "com.toolpouch.archive-tool")
    static let coordinateTool = Self(rawValue: "com.toolpouch.coordinate-tool")
    static let mediaFileInfo = Self(rawValue: "com.toolpouch.media-file-info")
    static let systemStats = Self(rawValue: "com.toolpouch.system-stats")

    /// Decodes identifiers persisted by versions released before tools used
    /// reverse-DNS identifiers. Unknown values remain decodable so removing a
    /// tool from one release does not corrupt the user's stored preferences.
    init(persistedValue: String) {
        self = Self.legacyIdentifiers[persistedValue]
            ?? Self(rawValue: persistedValue)
    }

    private static let legacyIdentifiers: [String: Self] = [
        "unitConverter": .unitConverter,
        "quickCopyNotes": .quickCopyNotes,
        "networkInfo": .networkInfo,
        "wiFiScanner": .wiFiScanner,
        "sshKeys": .sshKeys,
        "passwordGenerator": .passwordGenerator,
        "textEncoder": .textEncoder,
        "jsonToolkit": .jsonToolkit,
        "hashChecksum": .hashChecksum,
        "networkCheck": .networkCheck,
        "clipboardInspector": .clipboardInspector,
        "domainLookup": .domainLookup,
        "imageInspector": .imageInspector,
        "colorPicker": .colorPicker,
        "archiveTool": .archiveTool,
        "coordinateTool": .coordinateTool,
        "mediaFileInfo": .mediaFileInfo,
        "systemStats": .systemStats,
    ]
}
