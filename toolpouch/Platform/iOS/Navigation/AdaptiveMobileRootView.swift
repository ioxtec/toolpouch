#if os(iOS)
import SwiftUI

struct AdaptiveMobileRootView: View {
    let dependencies: AppDependencies

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            ThreeColumnToolNavigationView(dependencies: dependencies)
        } else {
            // Phones use the same capsule-based tool rows as the compact
            // macOS interface while retaining native iOS navigation.
            CompactToolNavigationView(
                dependencies: dependencies,
                preferredDensity: .compact
            )
        }
    }
}
#endif
