import Testing
@testable import toolpouch

@MainActor
struct ToolWindowNavigationModelTests {
    @Test
    func recordsRepeatedRequestsForTheSameTool() {
        let model = ToolWindowNavigationModel()

        model.request(.functionGraphs)
        let firstRequestID = model.requestID
        model.request(.functionGraphs)

        #expect(model.requestedToolID == .functionGraphs)
        #expect(model.requestID == firstRequestID + 1)
    }
}
