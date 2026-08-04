import Testing
@testable import toolpouch

struct WiFiNetworkTests {
    @Test(arguments: [
        (-110, 0.0),
        (-100, 0.0),
        (-75, 0.5),
        (-50, 1.0),
        (-30, 1.0),
    ])
    func signalQualityIsNormalized(rssi: Int, expectedQuality: Double) {
        let network = WiFiNetwork(
            id: "test",
            name: "Test Network",
            bssid: nil,
            rssi: rssi,
            channel: 1,
            isSecure: true
        )

        #expect(network.signalQuality == expectedQuality)
    }
}
