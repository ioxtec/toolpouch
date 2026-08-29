#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    let dependencies: AppDependencies

    var body: some View {
        // Compact density keeps the shared colored capsule style readable on
        // the smaller watch display without importing the macOS window chrome.
        CompactToolNavigationView(
            dependencies: dependencies,
            preferredDensity: .compact
        )
    }
}
#endif
