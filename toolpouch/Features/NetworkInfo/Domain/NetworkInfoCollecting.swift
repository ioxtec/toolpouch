protocol NetworkInfoCollecting: Sendable {
    func collect(for device: Device) async -> NetworkInfoSnapshot
}
