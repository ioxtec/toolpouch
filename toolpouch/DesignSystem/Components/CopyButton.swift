import SwiftUI

struct CopyButton: View {
    let value: String

    @State private var isShowingConfirmation = false

    var body: some View {
        Button {
            SystemClipboard.copy(value)
            showConfirmation()
        } label: {
            Image(systemName: isShowingConfirmation ? "checkmark" : "doc.on.doc")
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .help(isShowingConfirmation ? "Copied" : "Copy to Clipboard")
        .accessibilityLabel(isShowingConfirmation ? "Copied" : "Copy to Clipboard")
    }

    private func showConfirmation() {
        isShowingConfirmation = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            isShowingConfirmation = false
        }
    }
}
