nonisolated enum ToolCatalog {
    static let categories: [ToolCategory] = [
        ToolCategory(
            id: .network,
            title: "Network",
            description: "IP, DNS, Ping, HTTP...",
            systemImage: "network"
        ),
        ToolCategory(
            id: .security,
            title: "Security",
            description: "SSH, Keys, Hashes...",
            systemImage: "lock.shield"
        ),
        ToolCategory(
            id: .passwords,
            title: "Passwords",
            description: "Password generator",
            systemImage: "key.fill"
        ),
        ToolCategory(
            id: .clipboard,
            title: "Clipboard",
            description: "Snippets and notes",
            systemImage: "clipboard"
        ),
        ToolCategory(
            id: .design,
            title: "Design",
            description: "Colors and UI",
            systemImage: "paintpalette"
        ),
        ToolCategory(
            id: .images,
            title: "Images",
            description: "Resize and convert",
            systemImage: "photo.on.rectangle"
        ),
        ToolCategory(
            id: .text,
            title: "Text",
            description: "JSON, Base64...",
            systemImage: "textformat"
        ),
        ToolCategory(
            id: .sync,
            title: "Sync",
            description: "Shared files",
            systemImage: "icloud"
        ),
        ToolCategory(
            id: .utilities,
            title: "Utilities",
            description: "Timer and monitor",
            systemImage: "wrench.and.screwdriver"
        ),
    ]
}
