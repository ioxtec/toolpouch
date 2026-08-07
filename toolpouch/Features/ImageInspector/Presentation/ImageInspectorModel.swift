import Foundation
import Observation

@MainActor
@Observable
final class ImageInspectorModel {
    private let inspector: any ImageInspecting

    private(set) var selectedFileURL: URL?
    private(set) var inspection: ImageInspection?
    private(set) var metadata: ImageMetadata?
    private(set) var errorMessage: String?
    private(set) var isInspecting = false
    private(set) var isTransforming = false
    private(set) var transformedFileURL: URL?
    private(set) var transformMessage: String?

    init(inspector: any ImageInspecting) {
        self.inspector = inspector
    }

    /// Replaces the current selection and inspects the image on the inspector's actor.
    func select(_ url: URL) async {
        selectedFileURL = url
        inspection = nil
        metadata = nil
        errorMessage = nil
        transformedFileURL = nil
        transformMessage = nil
        isInspecting = true
        defer { isInspecting = false }

        do {
            let inspection = try await inspector.inspectImage(at: url)
            let metadata = try await inspector.readMetadata(at: url)
            self.inspection = inspection
            self.metadata = metadata
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        selectedFileURL = nil
        inspection = nil
        metadata = nil
        errorMessage = nil
        isInspecting = false
        transformedFileURL = nil
        transformMessage = nil
    }

    func showSelectionError(_ error: Error) {
        selectedFileURL = nil
        inspection = nil
        metadata = nil
        errorMessage = error.localizedDescription
        isInspecting = false
    }

    func transform(to outputURL: URL, options: ImageTransformOptions) async {
        guard let selectedFileURL else { return }
        isTransforming = true
        transformedFileURL = nil
        transformMessage = nil
        defer { isTransforming = false }

        do {
            try await inspector.transform(
                inputURL: selectedFileURL,
                outputURL: outputURL,
                options: options
            )
            transformedFileURL = outputURL
            transformMessage = "Image saved successfully."
        } catch {
            transformMessage = error.localizedDescription
        }
    }
}
