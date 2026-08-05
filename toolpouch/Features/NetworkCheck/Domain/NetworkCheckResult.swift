import Foundation

nonisolated struct NetworkCheckResult: Equatable, Sendable {
    enum PortStatus: Equatable, Sendable {
        case reachable(latencyMilliseconds: Int)
        case unreachable(reason: String)
    }

    let request: NetworkCheckRequest
    let addresses: [String]
    let portStatus: PortStatus
    let checkedAt: Date
}
