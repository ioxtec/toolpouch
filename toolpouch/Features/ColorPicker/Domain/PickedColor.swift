import Foundation

nonisolated struct PickedColor: Equatable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var hex: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var rgb: String {
        "rgb(\(red), \(green), \(blue))"
    }

    var hsl: String {
        let r = Double(red) / 255
        let g = Double(green) / 255
        let b = Double(blue) / 255
        let maximum = max(r, g, b)
        let minimum = min(r, g, b)
        let lightness = (maximum + minimum) / 2
        let difference = maximum - minimum
        guard difference > 0 else {
            return "hsl(0, 0%, \(Int((lightness * 100).rounded()))%)"
        }
        let saturation = difference / (1 - abs(2 * lightness - 1))
        let hue: Double
        if maximum == r {
            hue = 60 * (((g - b) / difference).truncatingRemainder(dividingBy: 6))
        } else if maximum == g {
            hue = 60 * ((b - r) / difference + 2)
        } else {
            hue = 60 * ((r - g) / difference + 4)
        }
        let normalizedHue = hue < 0 ? hue + 360 : hue
        return "hsl(\(Int(normalizedHue.rounded())), \(Int((saturation * 100).rounded()))%, \(Int((lightness * 100).rounded()))%)"
    }
}
