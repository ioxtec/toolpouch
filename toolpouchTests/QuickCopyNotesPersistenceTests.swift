import SwiftData
import Testing
@testable import toolpouch

@MainActor
struct QuickCopyNotesPersistenceTests {
    @Test
    func storesHierarchyAndPreservesMultilineContent() throws {
        let container = try makeQuickCopyContainer()
        let context = container.mainContext
        let folder = QuickCopyFolderRecord(title: "Work")
        context.insert(folder)
        try context.save()

        let collection = QuickCopyCollectionRecord(
            title: "Homebrew Commands",
            folder: folder
        )
        context.insert(collection)
        try context.save()

        let content = "brew update\nbrew upgrade\nbrew cleanup"
        let snippet = QuickCopySnippetRecord(
            title: "Update packages",
            content: content,
            collection: collection
        )
        context.insert(snippet)
        try context.save()

        let savedFolders = try context.fetch(
            FetchDescriptor<QuickCopyFolderRecord>()
        )

        #expect(savedFolders.count == 1)
        #expect(savedFolders.first?.collections?.first?.title == "Homebrew Commands")
        #expect(savedFolders.first?.collections?.first?.snippets?.first?.content == content)
    }

    @Test
    func deletingFolderCascadesThroughCollectionsAndNotes() throws {
        let container = try makeQuickCopyContainer()
        let context = container.mainContext
        let folder = QuickCopyFolderRecord(title: "Work")
        context.insert(folder)
        try context.save()

        let collection = QuickCopyCollectionRecord(
            title: "Shell",
            folder: folder
        )
        context.insert(collection)
        try context.save()

        let snippet = QuickCopySnippetRecord(
            title: "Upgrade",
            content: "apt update\napt upgrade",
            collection: collection
        )
        context.insert(snippet)
        try context.save()
        context.delete(folder)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<QuickCopyFolderRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<QuickCopyCollectionRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<QuickCopySnippetRecord>()).isEmpty)
    }

    /// Tests use the same schema boundary as the production CloudKit store.
    /// Mixing unrelated entities into this configuration would hide mistakes
    /// where a relationship crosses between the local and synchronized stores.
    private func makeQuickCopyContainer() throws -> ModelContainer {
        let schema = Schema([
            QuickCopyFolderRecord.self,
            QuickCopyCollectionRecord.self,
            QuickCopySnippetRecord.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
