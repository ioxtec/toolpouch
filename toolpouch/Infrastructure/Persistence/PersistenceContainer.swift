import OSLog
import SwiftData

enum PersistenceContainer {
    private static let logger = Logger(
        subsystem: "com.hoxim.toolpouch",
        category: "Persistence"
    )

    enum StorageMode {
        case cloudKitAutomatic
        case inMemory
        case local
    }

    /// Creates the shared SwiftData container using local, in-memory, or CloudKit-backed storage.
    static func makeModelContainer(
        mode: StorageMode = .cloudKitAutomatic
    ) -> ModelContainer {
        let schema = Schema([
            DeviceRecord.self,
            NetworkSnapshotRecord.self,
            QuickCopyFolderRecord.self,
            QuickCopyCollectionRecord.self,
            QuickCopySnippetRecord.self,
        ])
        do {
            return try ModelContainer(
                for: schema,
                configurations: configurations(for: mode, schema: schema)
            )
        } catch {
            guard case .cloudKitAutomatic = mode else {
                fatalError("Unable to create the model container: \(error)")
            }

            // A development profile may not contain the iCloud container yet,
            // and a signed-in device can temporarily lose CloudKit access. The
            // notes feature is offline-first, so neither situation should stop
            // the entire application from launching.
            logger.error(
                "CloudKit store unavailable; opening Quick Copy Notes locally. \(String(describing: error), privacy: .public)"
            )

            do {
                return try ModelContainer(
                    for: schema,
                    configurations: configurations(for: .local, schema: schema)
                )
            } catch {
                fatalError("Unable to create the local model container: \(error)")
            }
        }
    }

    private static func configurations(
        for mode: StorageMode,
        schema: Schema
    ) -> [ModelConfiguration] {
        switch mode {
        case .cloudKitAutomatic:
            // Only user-authored Quick Copy Notes belong in iCloud. Device and
            // network snapshots remain in the original local store so enabling
            // sync cannot upload unrelated diagnostic information.
            let localSchema = Schema([
                DeviceRecord.self,
                NetworkSnapshotRecord.self,
            ])
            let quickCopySchema = Schema([
                QuickCopyFolderRecord.self,
                QuickCopyCollectionRecord.self,
                QuickCopySnippetRecord.self,
            ])
            return [
                ModelConfiguration(
                    schema: localSchema,
                    cloudKitDatabase: .none
                ),
                ModelConfiguration(
                    "QuickCopyNotes",
                    schema: quickCopySchema,
                    cloudKitDatabase: .automatic
                ),
            ]
        case .inMemory:
            return [
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                ),
            ]
        case .local:
            // Keep the same store boundary as the CloudKit configuration. This
            // lets the app retry synchronization on a later launch without
            // mixing user notes with local diagnostic records.
            let localSchema = Schema([
                DeviceRecord.self,
                NetworkSnapshotRecord.self,
            ])
            let quickCopySchema = Schema([
                QuickCopyFolderRecord.self,
                QuickCopyCollectionRecord.self,
                QuickCopySnippetRecord.self,
            ])
            return [
                ModelConfiguration(
                    schema: localSchema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                ),
                ModelConfiguration(
                    "QuickCopyNotes",
                    schema: quickCopySchema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                ),
            ]
        }
    }
}
