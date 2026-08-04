#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    let dependencies: AppDependencies

    var body: some View {
        CompactToolNavigationView(dependencies: dependencies)
    }
}
#endif
