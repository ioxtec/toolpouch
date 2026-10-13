import Observation
import SwiftUI

@MainActor
@Observable
final class ToolWindowNavigationModel {
    private(set) var requestedToolID: ToolDefinition.ID?
    private(set) var requestID = 0

    func request(_ toolID: ToolDefinition.ID) {
        requestedToolID = toolID
        requestID += 1
    }
}

struct OpenToolInWindowAction {
    private let handler: ((ToolDefinition.ID) -> Void)?

    init(_ handler: ((ToolDefinition.ID) -> Void)? = nil) {
        self.handler = handler
    }

    var isAvailable: Bool { handler != nil }

    func callAsFunction(_ toolID: ToolDefinition.ID) {
        handler?(toolID)
    }
}

private struct OpenToolInWindowEnvironmentKey: EnvironmentKey {
    static let defaultValue = OpenToolInWindowAction()
}

extension EnvironmentValues {
    var openToolInWindow: OpenToolInWindowAction {
        get { self[OpenToolInWindowEnvironmentKey.self] }
        set { self[OpenToolInWindowEnvironmentKey.self] = newValue }
    }
}
