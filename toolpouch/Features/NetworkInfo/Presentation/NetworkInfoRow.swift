import SwiftUI

struct NetworkInfoRow: View {
    let field: NetworkInfoField

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: field.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(field.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(field.value)
                    .font(.callout.monospaced())
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 8)

            CopyButton(value: field.value)
        }
        .accessibilityElement(children: .contain)
    }
}
