#if os(iOS)
import SwiftUI

struct AdaptiveMobileRootView: View {
    let dependencies: AppDependencies

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            ThreeColumnToolNavigationView(dependencies: dependencies)
        } else {
            CompactToolNavigationView(dependencies: dependencies)
        }
    }
}
#endif
