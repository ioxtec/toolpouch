import Combine
import Foundation

@MainActor
final class MediaFileInfoModel: ObservableObject {
    private let inspector: any MediaFileInspecting

    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var inspection: MediaFileInspection?
    @Published private(set) var errorMessage: String?
    @Published private(set) var errorDetails: String?
    @Published private(set) var isInspecting = false
    @Published var isDropTargeted = false

    init(inspector: any MediaFileInspecting) {
        self.inspector = inspector
    }

    func select(_ url: URL) async {
        selectedFileURL = url
        inspection = nil
        errorMessage = nil
        errorDetails = nil
        isInspecting = true
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
            isInspecting = false
        }

        do {
            inspection = try await inspector.inspectMedia(at: url)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            errorDetails = (error as? MediaFileInspectionError)?.diagnosticSummary
                ?? Self.diagnosticSummary(for: error)
        }
    }

    func clear() {
        selectedFileURL = nil
        inspection = nil
        errorMessage = nil
        errorDetails = nil
        isInspecting = false
    }

    private nonisolated static func diagnosticSummary(for error: Error) -> String {
        let failure = error as NSError
        return "MediaFileInfo/error domain=\(failure.domain) code=\(failure.code)"
    }
}
