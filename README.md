# ToolPouch

ToolPouch is a native macOS menu bar app that brings small, useful developer tools together in one place.

## Current features

- Network details, including public IP, local IPv4 and IPv6, router, DNS servers, interface, and host name
- One-click copy for every network value
- Local network snapshot history for multiple devices
- Native menu bar controls with Settings, About, and Quit actions
- Liquid Glass interface built with SwiftUI
- Shared network collection code verified for macOS, iOS, and watchOS

## Project status

The macOS app is the primary interface. The data model and persistence layer are prepared for CloudKit so snapshots collected on other Apple devices can be displayed on the Mac. Cloud synchronization will be enabled after the iCloud container is provisioned.

## Requirements

- macOS 27 or later
- Xcode 27 or later
- Swift 6

## Running the app

Open `toolpouch.xcodeproj` in Xcode and run the `toolpouch` scheme, or use:

```bash
./script/build_and_run.sh
```

Left-click the ToolPouch icon to open the tool grid. Right-click it to open Settings, About, or quit the app.

## Structure

- `App` — application composition and navigation
- `Core` — shared models and contracts
- `Features` — feature-specific domain, data, and presentation code
- `Infrastructure` — persistence and future synchronization
- `Platform` — operating-system integrations
- `DesignSystem` — reusable SwiftUI components and layout values

More details are available in [Architecture](docs/Architecture.md).
