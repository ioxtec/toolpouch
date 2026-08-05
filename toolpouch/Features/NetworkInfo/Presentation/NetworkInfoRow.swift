import SwiftUI

struct NetworkInfoRow: View {
    let field: NetworkInfoField

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: field.systemImage)
                .toolPouchIcon(.small)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(field.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(field.value)
                .font(.caption.monospaced())
                .lineLimit(2)
                #if !os(watchOS)
                .textSelection(.enabled)
                #endif

            Spacer(minLength: 4)

            #if !os(watchOS)
            CopyButton(value: field.value)
            #endif
        }
        .accessibilityElement(children: .contain)
    }
}
