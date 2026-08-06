import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let contextMenu: NSMenu
    private let mainWindowController: MainWindowController

    init(dependencies: AppDependencies) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        contextMenu = NSMenu()
        mainWindowController = MainWindowController(dependencies: dependencies)

        super.init()

        configureStatusItem()
        configurePopover(dependencies: dependencies)
        configureContextMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        let image = NSImage(named: "MenuBarIcon") ?? NSImage(
            systemSymbolName: "shippingbox",
            accessibilityDescription: "ToolPouch"
        )
        image?.isTemplate = true
        button.image = image
        button.refusesFirstResponder = true
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover(dependencies: AppDependencies) {
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.contentSize = NSSize(
            width: ToolPouchLayout.MenuBar.width,
            height: ToolPouchLayout.MenuBar.height
        )
        let hostingController = PopoverHostingController(
            rootView: MenuBarRootView(
                dependencies: dependencies,
                openMainWindow: { [weak self] in
                    self?.openMainWindow()
                },
                close: { [weak self] in
                    self?.closePopover()
                }
            )
        )
        hostingController.onCancel = { [weak self] in
            self?.closePopover()
        }
        popover.contentViewController = hostingController

    }

    private func configureContextMenu() {
        contextMenu.delegate = self
        contextMenu.addItem(
            menuItem(
                title: "Open ToolPouch",
                systemImage: "macwindow",
                action: #selector(openMainWindow)
            )
        )
        contextMenu.addItem(.separator())
        contextMenu.addItem(
            menuItem(
                title: "Settings…",
                systemImage: "gearshape",
                action: #selector(openSettings),
                keyEquivalent: ","
            )
        )
        contextMenu.addItem(
            menuItem(
                title: "About ToolPouch",
                systemImage: "info.circle",
                action: #selector(openAbout)
            )
        )
        contextMenu.addItem(.separator())
        contextMenu.addItem(
            menuItem(
                title: "Quit ToolPouch",
                systemImage: "power",
                action: #selector(quit),
                keyEquivalent: "q"
            )
        )
    }

    @objc
    private func openMainWindow() {
        closePopover()
        mainWindowController.present()
    }

    private func menuItem(
        title: String,
        systemImage: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: keyEquivalent
        )
        item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        item.target = self
        return item
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseUp:
            closePopover()
            presentContextMenu()
        case .leftMouseUp:
            togglePopover(relativeTo: sender)
        default:
            return
        }
    }

    private func presentContextMenu() {
        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )

            Task { @MainActor [weak self] in
                await Task.yield()
                self?.popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
    }

    @objc
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: self
        )
    }

    @objc
    private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ToolPouch",
            .applicationVersion: "Version \(version)",
            .version: "Build \(build)",
        ])
    }

    @objc
    private func quit() {
        NSApp.terminate(self)
    }

    func menuWillOpen(_ menu: NSMenu) {
        closePopover()
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}

@MainActor
private final class PopoverHostingController<Content: View>:
    NSHostingController<Content>
{
    var onCancel: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
