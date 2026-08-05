#if os(macOS)
import Observation

@MainActor
@Observable
final class ColorPickerSession {
    static let shared = ColorPickerSession()

    private let picker = ScreenColorPicker()

    private(set) var selectedColor: PickedColor?
    private(set) var errorMessage: String?
    private(set) var isPicking = false

    private init() {}

    func start() {
        guard !isPicking else { return }
        errorMessage = nil
        isPicking = true

        picker.start(
            onPick: { [weak self] color in
                self?.selectedColor = color
                self?.isPicking = false
            },
            onError: { [weak self] message in
                self?.errorMessage = message
                self?.isPicking = false
            },
            onCancel: { [weak self] in
                self?.isPicking = false
            }
        )
    }

    func cancel() {
        picker.cancel()
    }
}
#endif
