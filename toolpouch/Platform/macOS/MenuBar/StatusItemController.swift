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

        button.image = NSImage(
            systemSymbolName: "shippingbox",
            accessibilityDescription: "ToolPouch"
        )
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover(dependencies: AppDependencies) {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(
            width: ToolPouchLayout.MenuBar.width,
            height: ToolPouchLayout.MenuBar.height
        )
        popover.contentViewController = NSHostingController(
            rootView: MenuBarRootView(dependencies: dependencies)
        )
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

        if event.type == .rightMouseUp {
            popover.performClose(nil)
            contextMenu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: sender.bounds.height),
                in: sender
            )
        } else {
            togglePopover(relativeTo: sender)
        }
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
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
        popover.performClose(nil)
    }
}
