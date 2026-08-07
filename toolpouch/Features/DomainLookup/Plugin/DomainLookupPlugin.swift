import SwiftUI

struct DomainLookupPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .domainLookup,
        categoryID: .network,
        title: "Whois",
        description: "Check registration details for a domain.",
        systemImage: "globe.badge.chevron.backward",
        supportedPlatforms: [.macOS, .iOS, .watchOS],
        executionBackend: .nativeSwift,
        requiredCapabilities: [.network]
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(DomainLookupView(service: RDAPDomainLookupClient()))
    }
}
