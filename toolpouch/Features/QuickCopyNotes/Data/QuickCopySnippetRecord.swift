import Foundation
import SwiftData

/// The actual copyable value. `content` is plain text on purpose so shell
/// commands, addresses, email templates, and multiline blocks all round-trip
/// without losing whitespace or line breaks.
@Model
final class QuickCopySnippetRecord {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var content: String = ""
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortOrder: Int = 0
    var collection: QuickCopyCollectionRecord?

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        content: String,
        isFavorite: Bool = false,
        collection: QuickCopyCollectionRecord? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.content = content
        self.isFavorite = isFavorite
        self.collection = collection
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}
