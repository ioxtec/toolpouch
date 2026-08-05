import SwiftData

enum PersistenceContainer {
    enum StorageMode {
        case cloudKitAutomatic
        case inMemory
        case local
    }

    /// Creates the shared SwiftData container using local, in-memory, or CloudKit-backed storage.
    static func makeModelContainer(
        mode: StorageMode = .local
    ) -> ModelContainer {
        let schema = Schema([
            DeviceRecord.self,
            NetworkSnapshotRecord.self,
        ])
        let configuration = configuration(for: mode, schema: schema)

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Unable to create the model container: \(error)")
        }
    }

    private static func configuration(
        for mode: StorageMode,
        schema: Schema
    ) -> ModelConfiguration {
        switch mode {
        case .cloudKitAutomatic:
            ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
        case .inMemory:
            ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        case .local:
            ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }
    }
}
