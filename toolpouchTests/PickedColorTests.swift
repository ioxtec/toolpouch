import Testing
@testable import toolpouch

struct PickedColorTests {
    @Test
    func formatsPrimaryRed() {
        let color = PickedColor(red: 255, green: 0, blue: 0)

        #expect(color.hex == "#FF0000")
        #expect(color.rgb == "rgb(255, 0, 0)")
        #expect(color.hsl == "hsl(0, 100%, 50%)")
    }

    @Test
    func formatsNeutralGrayWithoutUndefinedHue() {
        let color = PickedColor(red: 128, green: 128, blue: 128)

        #expect(color.hex == "#808080")
        #expect(color.hsl == "hsl(0, 0%, 50%)")
    }
}
