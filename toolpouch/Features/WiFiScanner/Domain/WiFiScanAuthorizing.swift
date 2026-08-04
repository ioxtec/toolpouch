@MainActor
protocol WiFiScanAuthorizing: Sendable {
    func authorize() async throws
}

nonisolated struct NoOpWiFiScanAuthorizer: WiFiScanAuthorizing {
    @MainActor
    func authorize() async throws {}
}
