import Testing
@testable import toolpouch

struct ToolCatalogTests {
    @Test
    func categoryIdentifiersAreUnique() {
        let identifiers = ToolCatalog.categories.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test
    func categoriesHaveCompletePresentationMetadata() {
        for category in ToolCatalog.categories {
            #expect(!category.title.isEmpty)
            #expect(!category.description.isEmpty)
            #expect(!category.systemImage.isEmpty)
        }
    }
}
