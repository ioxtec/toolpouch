#if os(macOS)
import AppKit
import ScreenCaptureKit

@MainActor
final class ScreenColorPicker {
    private var overlayWindows: [NSWindow] = []
    private var magnifierPanel: NSPanel?
    private var magnifierView: PixelMagnifierView?
    private var cursorPanel: NSPanel?
    private var instructionPanel: NSPanel?
    private var instructionDismissTask: Task<Void, Never>?
    private var keyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var sessionID: UUID?
    private var isCursorOverrideActive = false
    private var isCapturing = false
    private var latestColor: PickedColor?
    private var shouldCompleteOnNextCapture = false
    private var onPick: ((PickedColor) -> Void)?
    private var onError: ((String) -> Void)?
    private var onCancel: (() -> Void)?

    func start(
        onPick: @escaping (PickedColor) -> Void,
        onError: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        cleanUp(notifyCancellation: false)
        self.onPick = onPick
        self.onError = onError
        self.onCancel = onCancel

        guard ScreenCapturePermissionManager.shared.isGranted else {
            onError(
                "Screen Recording access is required. You can manage it in ToolPouch Settings."
            )
            return
        }

        let sessionID = UUID()
        self.sessionID = sessionID
        ColorPickerCursor.invisible.push()
        isCursorOverrideActive = true
        createMagnifier()
        createCursorIndicator()
        showInstruction(for: sessionID)
        createOverlays(for: sessionID)
        installEventMonitors(for: sessionID)

        let appKitPoint = NSEvent.mouseLocation
        let capturePoint = CGEvent(source: nil)?.location ?? appKitPoint
        moveMagnifier(near: appKitPoint)
        moveCursorIndicator(to: appKitPoint)
        capture(around: capturePoint, for: sessionID)
    }

    func cancel() {
        cleanUp(notifyCancellation: true)
    }

    private func cleanUp(notifyCancellation: Bool) {
        let cancellation = notifyCancellation ? onCancel : nil
        if isCursorOverrideActive {
            NSCursor.pop()
            NSCursor.arrow.set()
            isCursorOverrideActive = false
        }
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        magnifierPanel?.orderOut(nil)
        magnifierPanel = nil
        magnifierView = nil
        cursorPanel?.orderOut(nil)
        cursorPanel = nil
        instructionDismissTask?.cancel()
        instructionDismissTask = nil
        instructionPanel?.orderOut(nil)
        instructionPanel = nil
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        isCapturing = false
        sessionID = nil
        latestColor = nil
        shouldCompleteOnNextCapture = false
        onPick = nil
        onError = nil
        onCancel = nil
        cancellation?()
    }

    private func createOverlays(for sessionID: UUID) {
        overlayWindows = NSScreen.screens.map { screen in
            let window = ColorCaptureWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.acceptsMouseMovedEvents = true
            window.sharingType = .none
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let overlay = ColorCaptureOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            overlay.onMove = { [weak self] appKitPoint, capturePoint in
                guard self?.sessionID == sessionID else { return }
                self?.moveMagnifier(near: appKitPoint)
                self?.moveCursorIndicator(to: appKitPoint)
                self?.capture(around: capturePoint, for: sessionID)
            }
            overlay.onCancel = { [weak self] in
                guard self?.sessionID == sessionID else { return }
                self?.cancel()
            }
            window.contentView = overlay
            window.orderFrontRegardless()
            return window
        }

        let pointer = NSEvent.mouseLocation
        let activeWindow = overlayWindows.first(where: { $0.frame.contains(pointer) })
            ?? overlayWindows.first
        NSApp.activate(ignoringOtherApps: true)
        if let activeWindow {
            activeWindow.makeKeyAndOrderFront(nil)
            activeWindow.makeFirstResponder(activeWindow.contentView)
        }
    }

    private func createMagnifier() {
        let size = NSSize(width: 210, height: 238)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.sharingType = .none
        panel.hidesOnDeactivate = false
        panel.level = .screenSaver + 1
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = PixelMagnifierView(frame: NSRect(origin: .zero, size: size))
        panel.contentView = view
        panel.orderFrontRegardless()
        magnifierPanel = panel
        magnifierView = view
    }

    private func createCursorIndicator() {
        let size = NSSize(width: 30, height: 30)
        let panel = makeFloatingPanel(size: size, level: .screenSaver + 2)
        panel.contentView = ColorTargetView(frame: NSRect(origin: .zero, size: size))
        panel.orderFrontRegardless()
        cursorPanel = panel
    }

    private func showInstruction(for sessionID: UUID) {
        let size = NSSize(width: 286, height: 48)
        let panel = makeFloatingPanel(size: size, level: .screenSaver + 3)
        panel.contentView = PickerInstructionView(frame: NSRect(origin: .zero, size: size))

        let point = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) })
            ?? NSScreen.main
        if let screen {
            panel.setFrameOrigin(
                NSPoint(
                    x: screen.visibleFrame.midX - size.width / 2,
                    y: screen.visibleFrame.maxY - size.height - 28
                )
            )
        }
        panel.orderFrontRegardless()
        instructionPanel = panel

        instructionDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, self?.sessionID == sessionID else { return }
            self?.instructionPanel?.orderOut(nil)
            self?.instructionPanel = nil
        }
    }

    private func makeFloatingPanel(size: NSSize, level: NSWindow.Level) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.sharingType = .none
        panel.hidesOnDeactivate = false
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func installEventMonitors(for sessionID: UUID) {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            guard self?.sessionID == sessionID else { return event }
            self?.cancel()
            return nil
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            guard event.keyCode == 53, self?.sessionID == sessionID else { return }
            self?.cancel()
        }

        // A menu bar popup may close before its transparent overlay receives mouseDown.
        // Observe both application and system clicks so a selection always completes.
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) {
            [weak self] event in
            guard self?.sessionID == sessionID else { return event }
            self?.selectVisibleColor(for: sessionID)
            return nil
        }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) {
            [weak self] _ in
            self?.selectVisibleColor(for: sessionID)
        }
    }

    private func capture(around point: CGPoint, for sessionID: UUID) {
        guard self.sessionID == sessionID, !isCapturing else { return }
        isCapturing = true
        let sampleSize: CGFloat = 15
        let rect = CGRect(
            x: point.x - sampleSize / 2,
            y: point.y - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        SCScreenshotManager.captureImage(in: rect) { [weak self] image, error in
            Task { @MainActor in
                guard let self, self.sessionID == sessionID else { return }
                self.isCapturing = false
                guard let image, error == nil,
                      let color = Self.centerColor(in: image) else {
                    if self.shouldCompleteOnNextCapture {
                        self.onError?("ToolPouch could not sample this part of the screen.")
                        self.cleanUp(notifyCancellation: false)
                    }
                    return
                }
                self.latestColor = color
                self.magnifierView?.update(image: image, color: color)
                if self.shouldCompleteOnNextCapture {
                    self.finishSelection(with: color)
                }
            }
        }
    }

    private func selectVisibleColor(for sessionID: UUID) {
        guard self.sessionID == sessionID else { return }
        if let latestColor {
            finishSelection(with: latestColor)
        } else {
            shouldCompleteOnNextCapture = true
        }
    }

    private func finishSelection(with color: PickedColor) {
        let completion = onPick
        cleanUp(notifyCancellation: false)
        completion?(color)
    }

    private func moveMagnifier(near point: NSPoint) {
        guard let panel = magnifierPanel,
              let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) else {
            return
        }
        let margin: CGFloat = 18
        var origin = NSPoint(x: point.x + 26, y: point.y - panel.frame.height - 26)
        if origin.x + panel.frame.width > screen.visibleFrame.maxX - margin {
            origin.x = point.x - panel.frame.width - 26
        }
        if origin.y < screen.visibleFrame.minY + margin {
            origin.y = point.y + 26
        }
        panel.setFrameOrigin(origin)
    }

    private func moveCursorIndicator(to point: NSPoint) {
        guard let panel = cursorPanel else { return }
        panel.setFrameOrigin(
            NSPoint(
                x: point.x - panel.frame.width / 2,
                y: point.y - panel.frame.height / 2
            )
        )
        panel.orderFrontRegardless()
    }

    private static func centerColor(in image: CGImage) -> PickedColor? {
        let x = max(0, image.width / 2)
        let y = max(0, image.height / 2)
        guard let pixel = image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else {
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &bytes,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return PickedColor(red: bytes[0], green: bytes[1], blue: bytes[2])
    }
}

private final class ColorCaptureWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private final class ColorCaptureOverlayView: NSView {
    var onMove: ((NSPoint, CGPoint) -> Void)?
    var onCancel: (() -> Void)?
    private var trackingAreaReference: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference {
            removeTrackingArea(trackingAreaReference)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaReference = trackingArea
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: ColorPickerCursor.invisible)
    }

    override func cursorUpdate(with event: NSEvent) {
        ColorPickerCursor.invisible.set()
    }

    override func mouseMoved(with event: NSEvent) {
        ColorPickerCursor.invisible.set()
        let appKitPoint = NSEvent.mouseLocation
        let capturePoint = CGEvent(source: nil)?.location ?? appKitPoint
        onMove?(appKitPoint, capturePoint)
        ColorPickerCursor.invisible.set()
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else {
            super.keyDown(with: event)
            return
        }
        onCancel?()
    }
}

private enum ColorPickerCursor {
    static let invisible: NSCursor = {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        return NSCursor(image: image, hotSpot: .zero)
    }()
}

private final class ColorTargetView: NSView {
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)

        let outerCircle = NSBezierPath(
            ovalIn: NSRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)
        )
        outerCircle.lineWidth = 4
        NSColor.white.setStroke()
        outerCircle.stroke()

        let innerCircle = NSBezierPath(
            ovalIn: NSRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)
        )
        innerCircle.lineWidth = 2
        NSColor.black.setStroke()
        innerCircle.stroke()

        drawCrosshair(center: center, color: .white, lineWidth: 4)
        drawCrosshair(center: center, color: .black, lineWidth: 2)
    }

    private func drawCrosshair(center: NSPoint, color: NSColor, lineWidth: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.move(to: NSPoint(x: center.x, y: 1))
        path.line(to: NSPoint(x: center.x, y: 8))
        path.move(to: NSPoint(x: center.x, y: bounds.maxY - 8))
        path.line(to: NSPoint(x: center.x, y: bounds.maxY - 1))
        path.move(to: NSPoint(x: 1, y: center.y))
        path.line(to: NSPoint(x: 8, y: center.y))
        path.move(to: NSPoint(x: bounds.maxX - 8, y: center.y))
        path.line(to: NSPoint(x: bounds.maxX - 1, y: center.y))
        color.setStroke()
        path.stroke()
    }
}

private final class PickerInstructionView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true

        let icon = NSImageView(
            image: NSImage(
                systemSymbolName: "escape",
                accessibilityDescription: nil
            ) ?? NSImage()
        )
        icon.contentTintColor = .secondaryLabelColor
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: "Press Esc to exit Color Picking")
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(icon)
        addSubview(label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 19),
            icon.heightAnchor.constraint(equalToConstant: 19),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}

private final class PixelMagnifierView: NSView {
    private var image: CGImage?
    private var color: PickedColor?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(image: CGImage, color: PickedColor) {
        self.image = image
        self.color = color
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        let imageRect = NSRect(x: 12, y: 46, width: 186, height: 180)
        if let image, let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.interpolationQuality = .none
            context.draw(image, in: imageRect)
            context.restoreGState()
            drawGrid(in: imageRect, columns: image.width, rows: image.height)
        }

        let value = color?.hex ?? "Move the pointer"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
        ]
        if let color {
            drawColorSwatch(color, in: NSRect(x: 14, y: 9, width: 28, height: 28))
        }
        let text = NSAttributedString(string: value, attributes: attributes)
        text.draw(at: NSPoint(x: color == nil ? 14 : 52, y: 14))
    }

    private func drawColorSwatch(_ color: PickedColor, in rect: NSRect) {
        let swatch = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor(
            srgbRed: CGFloat(color.red) / 255,
            green: CGFloat(color.green) / 255,
            blue: CGFloat(color.blue) / 255,
            alpha: 1
        ).setFill()
        swatch.fill()

        swatch.lineWidth = 2
        NSColor.white.withAlphaComponent(0.65).setStroke()
        swatch.stroke()

        let outline = NSBezierPath(roundedRect: rect.insetBy(dx: -1, dy: -1), xRadius: 7, yRadius: 7)
        outline.lineWidth = 1
        NSColor.black.withAlphaComponent(0.55).setStroke()
        outline.stroke()
    }

    private func drawGrid(in rect: NSRect, columns: Int, rows: Int) {
        guard columns > 0, rows > 0 else { return }
        let cellWidth = rect.width / CGFloat(columns)
        let cellHeight = rect.height / CGFloat(rows)
        let path = NSBezierPath()
        path.lineWidth = 0.5
        for column in 0...columns {
            let x = rect.minX + CGFloat(column) * cellWidth
            path.move(to: NSPoint(x: x, y: rect.minY))
            path.line(to: NSPoint(x: x, y: rect.maxY))
        }
        for row in 0...rows {
            let y = rect.minY + CGFloat(row) * cellHeight
            path.move(to: NSPoint(x: rect.minX, y: y))
            path.line(to: NSPoint(x: rect.maxX, y: y))
        }
        NSColor.black.withAlphaComponent(0.28).setStroke()
        path.stroke()

        let center = NSRect(
            x: rect.midX - cellWidth / 2,
            y: rect.midY - cellHeight / 2,
            width: cellWidth,
            height: cellHeight
        )
        let marker = NSBezierPath(rect: center.insetBy(dx: -1, dy: -1))
        marker.lineWidth = 3
        NSColor.white.setStroke()
        marker.stroke()
        let outline = NSBezierPath(rect: center.insetBy(dx: -2.5, dy: -2.5))
        outline.lineWidth = 1
        NSColor.black.setStroke()
        outline.stroke()
    }
}
#endif
