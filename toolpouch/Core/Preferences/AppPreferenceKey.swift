nonisolated enum AppPreferenceKey {
    static let refreshNetworkInfoOnOpen = "refreshNetworkInfoOnOpen"
    static let sshKeyFolderBookmark = "sshKeyFolderBookmark"

    static func quickAccessToolIDs(for platform: ToolPlatform) -> String {
        "quickAccessToolIDs.\(platform.rawValue)"
    }
}
