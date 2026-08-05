protocol NetworkInfoCollecting: Sendable {
    /// Combines local interface details and public address data into a snapshot for one device.
    func collect(for device: Device) async -> NetworkInfoSnapshot
}
