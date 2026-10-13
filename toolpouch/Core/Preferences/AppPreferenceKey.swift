nonisolated enum AppPreferenceKey {
    static let refreshNetworkInfoOnOpen = "refreshNetworkInfoOnOpen"
    static let selectedThemeID = "selectedThemeID"
    static let interfaceLanguage = "interfaceLanguage"
    static let sshKeyFolderBookmark = "sshKeyFolderBookmark"
    static let systemStatsHistoryDuration = "systemStatsHistoryDuration"
    static let quickCopySelectedFolderID = "quickCopySelectedFolderID"
    static let functionGraphExpression = "functionGraphExpression"
    static let functionGraphLowerBound = "functionGraphLowerBound"
    static let functionGraphUpperBound = "functionGraphUpperBound"
    static let functionGraphAngleUnit = "functionGraphAngleUnit"

    static func quickAccessToolIDs(for platform: ToolPlatform) -> String {
        "quickAccessToolIDs.\(platform.rawValue)"
    }
}
