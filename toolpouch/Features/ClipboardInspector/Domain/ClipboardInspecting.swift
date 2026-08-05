#if os(macOS)
@MainActor
/// Provides a small, testable boundary around the macOS system pasteboard.
protocol ClipboardInspecting {
    var changeCount: Int { get }

    /// Captures the current pasteboard types and a safe preview of their contents.
    func readSnapshot() -> ClipboardSnapshot
    func clear()
}
#endif
