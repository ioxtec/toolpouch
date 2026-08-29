import Foundation
import SwiftData

/// A named group inside a folder, such as "Homebrew Commands".
/// Keeping this as a separate level makes a folder useful without forcing an
/// unlimited and difficult-to-navigate nesting system.
@Model
final class QuickCopyCollectionRecord {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortOrder: Int = 0
    var folder: QuickCopyFolderRecord?

    @Relationship(
        deleteRule: .cascade,
        inverse: \QuickCopySnippetRecord.collection
    )
    var snippets: [QuickCopySnippetRecord]? = []

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        folder: QuickCopyFolderRecord? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.folder = folder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}
