import Darwin
import Foundation
import Network

nonisolated struct SystemNetworkChecker: NetworkChecking {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 5) {
        self.timeout = timeout
    }

    func check(_ request: NetworkCheckRequest) async throws -> NetworkCheckResult {
        let addresses = try await resolve(request.host)
        let startedAt = ContinuousClock.now
        let portStatus: NetworkCheckResult.PortStatus

        do {
            try await TCPConnectionAttempt(
                host: request.host,
                port: request.port,
                timeout: timeout
            ).run()
            let elapsed = startedAt.duration(to: .now)
            let milliseconds = max(
                1,
                Int(elapsed.components.seconds * 1_000)
                    + Int(elapsed.components.attoseconds / 1_000_000_000_000_000)
            )
            portStatus = .reachable(latencyMilliseconds: milliseconds)
        } catch {
            portStatus = .unreachable(reason: error.localizedDescription)
        }

        return NetworkCheckResult(
            request: request,
            addresses: addresses,
            portStatus: portStatus,
            checkedAt: .now
        )
    }

    private func resolve(_ host: String) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_STREAM
            hints.ai_protocol = IPPROTO_TCP
            hints.ai_flags = AI_ADDRCONFIG

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, nil, &hints, &result)
            guard status == 0 else {
                if status == EAI_NONAME {
                    throw NetworkCheckError.hostNotFound
                }
                throw NetworkCheckError.lookupFailed(
                    String(cString: gai_strerror(status))
                )
            }
            defer { freeaddrinfo(result) }

            var addresses: [String] = []
            var current = result
            while let info = current?.pointee {
                try Task.checkCancellation()
                if let address = Self.numericAddress(from: info),
                   !addresses.contains(address) {
                    addresses.append(address)
                }
                current = info.ai_next
            }

            guard !addresses.isEmpty else {
                throw NetworkCheckError.hostNotFound
            }
            return addresses
        }.value
    }

    private static func numericAddress(from info: addrinfo) -> String? {
        guard let socketAddress = info.ai_addr else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = getnameinfo(
            socketAddress,
            info.ai_addrlen,
            &buffer,
            socklen_t(buffer.count),
            nil,
            0,
            NI_NUMERICHOST
        )
        guard status == 0 else { return nil }
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}

nonisolated private final class TCPConnectionAttempt: @unchecked Sendable {
    private enum AttemptError: LocalizedError {
        case unavailable(String)
        case timedOut

        var errorDescription: String? {
            switch self {
            case let .unavailable(reason): reason
            case .timedOut: "The connection timed out."
            }
        }
    }

    private let connection: NWConnection
    private let queue = DispatchQueue(label: "app.toolpouch.network-check")
    private let timeout: TimeInterval
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, any Error>?

    init(host: String, port: UInt16, timeout: TimeInterval) {
        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .tcp
        )
        self.timeout = timeout
    }

    func run() async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.withLock {
                    self.continuation = continuation
                }
                connection.stateUpdateHandler = { [weak self] state in
                    switch state {
                    case .ready:
                        self?.finish(with: .success(()))
                    case let .failed(error), let .waiting(error):
                        self?.finish(
                            with: .failure(AttemptError.unavailable(error.localizedDescription))
                        )
                    case .cancelled:
                        self?.finish(with: .failure(CancellationError()))
                    default:
                        break
                    }
                }
                connection.start(queue: queue)
                queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
                    self?.finish(with: .failure(AttemptError.timedOut))
                }
            }
        } onCancel: {
            finish(with: .failure(CancellationError()))
        }
    }

    private func finish(with result: Result<Void, any Error>) {
        let continuation = lock.withLock {
            defer { self.continuation = nil }
            return self.continuation
        }
        guard let continuation else { return }
        connection.stateUpdateHandler = nil
        connection.cancel()
        continuation.resume(with: result)
    }
}
