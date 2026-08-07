import Foundation
import Testing
@testable import toolpouch

struct CapabilityResolverTests {
    @Test
    func macResolvesPlatformSpecificCapabilities() {
        let resolver = SystemCapabilityResolver(platform: .macOS)

        #expect(resolver.hasCapability(.screenCapture))
        #expect(resolver.hasCapability(.clipboard))
        #expect(resolver.hasCapability(.wiFiScanning))
        #expect(resolver.hasCapability(.sshKeys))
        #expect(resolver.hasCapability(.network))
        #expect(resolver.hasCapability(.rustEngine))
        #expect(resolver.hasCapability(.gridLayout))
    }

    @Test
    func iOSDoesNotExposeMacOnlyCapabilities() {
        let resolver = SystemCapabilityResolver(platform: .iOS)

        #expect(!resolver.hasCapability(.screenCapture))
        #expect(!resolver.hasCapability(.clipboard))
        #expect(!resolver.hasCapability(.wiFiScanning))
        #expect(!resolver.hasCapability(.sshKeys))
        #expect(resolver.hasCapability(.network))
        #expect(resolver.hasCapability(.rustEngine))
        #expect(resolver.hasCapability(.gridLayout))
    }

    @Test
    func watchOSDoesNotExposeMacOnlyOrGridCapabilities() {
        let resolver = SystemCapabilityResolver(platform: .watchOS)

        #expect(!resolver.hasCapability(.screenCapture))
        #expect(!resolver.hasCapability(.clipboard))
        #expect(!resolver.hasCapability(.wiFiScanning))
        #expect(!resolver.hasCapability(.sshKeys))
        #expect(resolver.hasCapability(.network))
        #expect(resolver.hasCapability(.rustEngine))
        #expect(!resolver.hasCapability(.gridLayout))
    }

    @Test
    func supportsRequiresAllCapabilities() {
        let macResolver = SystemCapabilityResolver(platform: .macOS)
        let iOSResolver = SystemCapabilityResolver(platform: .iOS)

        #expect(macResolver.supports(requiredCapabilities: [.clipboard, .network]))
        #expect(!iOSResolver.supports(requiredCapabilities: [.clipboard, .network]))
    }

    @Test
    func emptyCapabilitiesAreAlwaysSupported() {
        let resolver = SystemCapabilityResolver(platform: .watchOS)

        #expect(resolver.supports(requiredCapabilities: []))
    }
}
