import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
final class SystemDeviceProvider: CurrentDeviceProviding {
    private enum Keys {
        static let deviceID = "currentDeviceID"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentDevice() -> Device {
        Device(
            id: deviceID,
            name: ProcessInfo.processInfo.hostName,
            kind: deviceKind,
            lastSeenAt: Date()
        )
    }

    private var deviceID: UUID {
        if let storedID = defaults.string(forKey: Keys.deviceID),
           let id = UUID(uuidString: storedID) {
            return id
        }

        let id = UUID()
        defaults.set(id.uuidString, forKey: Keys.deviceID)
        return id
    }

    private var deviceKind: DeviceKind {
#if os(macOS)
        .desktop
#elseif os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .phone
#elseif os(watchOS)
        .watch
#elseif os(tvOS)
        .television
#elseif os(visionOS)
        .spatialComputer
#else
        .unknown
#endif
    }
}
