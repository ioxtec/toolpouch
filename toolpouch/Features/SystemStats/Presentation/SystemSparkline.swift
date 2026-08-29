import SwiftUI

/// A deliberately small chart for recent samples. It has no axes because the
/// exact value is always displayed beside the chart and remains accessible.
struct SystemSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let clamped = values.map { min(max($0, 0), 1) }
            var path = Path()
            for (index, value) in clamped.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(clamped.count - 1)
                let y = size.height * CGFloat(1 - value)
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(color), lineWidth: 2)
        }
        .accessibilityHidden(true)
    }
}
