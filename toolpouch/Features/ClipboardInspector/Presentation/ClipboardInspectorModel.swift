#if os(macOS)
import Foundation
import Observation

@MainActor
@Observable
final class ClipboardInspectorModel {
    private let inspector: any ClipboardInspecting

    private(set) var snapshot: ClipboardSnapshot

    init(inspector: any ClipboardInspecting) {
        self.inspector = inspector
        snapshot = .empty(changeCount: inspector.changeCount)
    }

    func monitor() async {
        refresh()

        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            if inspector.changeCount != snapshot.changeCount {
                refresh()
            }
        }
    }

    func refresh() {
        snapshot = inspector.readSnapshot()
    }

    func clear() {
        inspector.clear()
        refresh()
    }
}
#endif
