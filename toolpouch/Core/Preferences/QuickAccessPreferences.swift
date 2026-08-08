import Foundation
import Observation

@MainActor
@Observable
final class QuickAccessPreferences {
    private let defaults: UserDefaults
    private let storageKey: String

    let maximumCount: Int
    private(set) var toolIDs: [ToolDefinition.ID]

    init(
        platform: ToolPlatform,
        defaultToolIDs: [ToolDefinition.ID],
        maximumCount: Int,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        storageKey = AppPreferenceKey.quickAccessToolIDs(for: platform)
        self.maximumCount = maximumCount

        if defaults.object(forKey: storageKey) != nil {
            let storedIDs = defaults.stringArray(forKey: storageKey) ?? []
            let decodedIDs = storedIDs.map(
                ToolDefinition.ID.init(persistedValue:)
            )
            toolIDs = Self.normalized(
                decodedIDs,
                maximumCount: maximumCount
            )
            let migratedValues = toolIDs.map(\.rawValue)
            if migratedValues != storedIDs {
                defaults.set(migratedValues, forKey: storageKey)
            }
        } else {
            toolIDs = Array(defaultToolIDs.prefix(maximumCount))
        }
    }

    func save(_ toolIDs: [ToolDefinition.ID]) {
        let normalizedIDs = Self.normalized(
            toolIDs,
            maximumCount: maximumCount
        )
        self.toolIDs = normalizedIDs
        defaults.set(normalizedIDs.map(\.rawValue), forKey: storageKey)
    }

    private static func normalized(
        _ toolIDs: [ToolDefinition.ID],
        maximumCount: Int
    ) -> [ToolDefinition.ID] {
        var seen = Set<ToolDefinition.ID>()
        return Array(
            toolIDs
                .filter { seen.insert($0).inserted }
                .prefix(maximumCount)
        )
    }
}
