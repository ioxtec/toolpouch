import AppKit
import SwiftData
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let contextMenu: NSMenu
    private let mainWindowController: MainWindowController
    private let settingsWindowController: SettingsWindowController

    init(dependencies: AppDependencies) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        contextMenu = NSMenu()
        mainWindowController = MainWindowController(dependencies: dependencies)
        settingsWindowController = SettingsWindowController(dependencies: dependencies)

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
                openMainWindow: { [weak self] toolID in
                    self?.presentMainWindow(toolID: toolID)
                },
                openSettings: { [weak self] in
                    self?.closePopover()
                    self?.openSettings()
                },
                close: { [weak self] in
                    self?.closePopover()
                },
                resizeToFit: { [weak self] requestedHeight in
                    self?.resizePopover(toFit: requestedHeight)
                        ?? ToolPouchLayout.MenuBar.height
                }
            )
            .environmentObject(dependencies.themeStore)
            .appLanguage(dependencies.languageStore)
            .toolPouchTheme(dependencies.themeStore)
            .modelContainer(dependencies.modelContainer)
        )
        hostingController.onCancel = { [weak self] in
            self?.closePopover()
        }
        popover.contentViewController = hostingController

    }

    /// Keeps the popover close to its content while respecting the usable area
    /// of whichever display currently owns the menu-bar item.
    private func resizePopover(toFit requestedHeight: CGFloat) -> CGFloat {
        let screen = statusItem.button?.window?.screen ?? NSScreen.main
        let availableHeight = max(
            ToolPouchLayout.MenuBar.minimumHeight,
            (screen?.visibleFrame.height ?? ToolPouchLayout.MenuBar.height)
                - ToolPouchLayout.MenuBar.screenMargin
        )
        let fittedHeight = min(
            max(requestedHeight, ToolPouchLayout.MenuBar.minimumHeight),
            availableHeight
        )

        guard abs(popover.contentSize.height - fittedHeight) > 1 else {
            return fittedHeight
        }

        popover.contentSize = NSSize(
            width: ToolPouchLayout.MenuBar.width,
            height: fittedHeight
        )
        return fittedHeight
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
        presentMainWindow(toolID: nil)
    }

    private func presentMainWindow(toolID: ToolDefinition.ID?) {
        closePopover()
        mainWindowController.present(toolID: toolID)
    }

    private func menuItem(
        title: String,
        systemImage: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title.localizedInterfaceText,
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
        contextMenu.removeAllItems()
        configureContextMenu()
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
        closePopover()
        settingsWindowController.present()
    }

    @objc
    private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let appVersion = AppVersionInfo.current

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ToolPouch",
            .applicationVersion: "Version \(appVersion.version)",
            .version: "Build \(appVersion.build)",
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
