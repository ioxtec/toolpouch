nonisolated protocol NetworkChecking: Sendable {
    /// Runs the requested reachability or connection check and measures its result.
    func check(_ request: NetworkCheckRequest) async throws -> NetworkCheckResult
}
