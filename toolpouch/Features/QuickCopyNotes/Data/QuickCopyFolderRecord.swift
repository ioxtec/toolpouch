import Foundation
import SwiftData

/// Top-level container created by the user, for example "Work" or "Personal".
///
/// The persisted name intentionally stays generic. The visible term can change
/// later without migrating the user's saved hierarchy.
@Model
final class QuickCopyFolderRecord {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortOrder: Int = 0

    @Relationship(
        deleteRule: .cascade,
        inverse: \QuickCopyCollectionRecord.folder
    )
    var collections: [QuickCopyCollectionRecord]? = []

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}
