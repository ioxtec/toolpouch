import Darwin
import Foundation
#if os(macOS)
import SystemConfiguration
#endif

nonisolated struct SystemLocalNetworkInfoProvider: LocalNetworkInfoProviding {
    func read() -> LocalNetworkInfo {
#if os(macOS)
        let primaryInterface = dynamicStoreValue(
            path: "State:/Network/Global/IPv4",
            key: "PrimaryInterface"
        ) as? String
        let addresses = addresses(for: primaryInterface)
        let router = dynamicStoreValue(
            path: "State:/Network/Global/IPv4",
            key: "Router"
        ) as? String
        let dnsServers = dynamicStoreValue(
            path: "State:/Network/Global/DNS",
            key: "ServerAddresses"
        ) as? [String] ?? []
#else
        let addresses = addresses(for: nil)
        let primaryInterface = addresses.interfaceName
        let router: String? = nil
        let dnsServers: [String] = []
#endif

        return LocalNetworkInfo(
            isConnected: primaryInterface != nil && addresses.ipv4 != nil,
            connectionKind: connectionKind(for: primaryInterface),
            interfaceName: primaryInterface,
            localIPv4Address: addresses.ipv4,
            localIPv6Address: addresses.ipv6,
            routerIPAddress: router,
            dnsServers: dnsServers,
            hostName: ProcessInfo.processInfo.hostName
        )
    }

#if os(macOS)
    private func dynamicStoreValue(path: String, key: String) -> Any? {
        guard let values = SCDynamicStoreCopyValue(nil, path as CFString)
            as? [String: Any] else {
            return nil
        }

        return values[key]
    }
#endif

    private func addresses(
        for preferredInterface: String?
    ) -> (interfaceName: String?, ipv4: String?, ipv6: String?) {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let firstAddress = pointer else {
            return (nil, nil, nil)
        }
        defer { freeifaddrs(pointer) }

        var ipv4: String?
        var ipv6: String?
        var resolvedInterface: String?
        var address = firstAddress

        while true {
            let interface = String(cString: address.pointee.ifa_name)
            let isEligible = interface != "lo0"
                && (address.pointee.ifa_flags & UInt32(IFF_UP)) != 0
                && (preferredInterface == nil || interface == preferredInterface)

            if isEligible, let socketAddress = address.pointee.ifa_addr {
                let family = socketAddress.pointee.sa_family
                if family == UInt8(AF_INET), ipv4 == nil {
                    ipv4 = numericAddress(from: socketAddress)
                    resolvedInterface = interface
                } else if family == UInt8(AF_INET6), ipv6 == nil {
                    ipv6 = numericAddress(from: socketAddress)
                    resolvedInterface = resolvedInterface ?? interface
                }
            }

            guard let next = address.pointee.ifa_next else { break }
            address = next
        }

        return (resolvedInterface, ipv4, ipv6)
    }

    private func numericAddress(from address: UnsafePointer<sockaddr>) -> String? {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            address,
            socklen_t(address.pointee.sa_len),
            &host,
            socklen_t(host.count),
            nil,
            0,
            NI_NUMERICHOST
        )

        guard result == 0 else { return nil }
        let bytes = host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func connectionKind(for interface: String?) -> NetworkConnectionKind {
        guard let interface else { return .unavailable }

#if os(macOS)
        if let systemKind = systemConnectionKind(for: interface) {
            return systemKind
        }
#endif

        if interface.hasPrefix("en") {
            return .wiFi
        }
        if interface.hasPrefix("pdp_ip") {
            return .cellular
        }
        if interface.hasPrefix("bridge") || interface.hasPrefix("eth") {
            return .ethernet
        }
        return .other
    }

#if os(macOS)
    private func systemConnectionKind(
        for interfaceName: String
    ) -> NetworkConnectionKind? {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface],
              let interface = interfaces.first(where: {
                  SCNetworkInterfaceGetBSDName($0) as String? == interfaceName
              }),
              let interfaceType = SCNetworkInterfaceGetInterfaceType(interface) as String? else {
            return nil
        }

        let wiFiType = kSCNetworkInterfaceTypeIEEE80211 as String
        let ethernetType = kSCNetworkInterfaceTypeEthernet as String

        if interfaceType == wiFiType {
            return .wiFi
        }
        if interfaceType == ethernetType {
            return .ethernet
        }
        return nil
    }
#endif
}
