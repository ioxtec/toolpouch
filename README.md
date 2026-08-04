# ToolPouch

ToolPouch is a native, multiplatform collection of focused developer utilities for Apple devices.

## Current features

- Network details, including public IP, local IPv4 and IPv6, router, DNS servers, interface, and host name
- One-click copy for every network value
- Local network snapshot history for multiple devices
- Native menu bar controls with Settings, About, and Quit actions
- Nearby Wi-Fi scanning with channel and RSSI details on macOS
- SSH key browsing and generation with persistent access to a user-selected key folder on macOS
- Compact navigation for iPhone and Apple Watch
- Three-column navigation for iPad and the optional macOS app window
- Liquid Glass interface built with SwiftUI
- Shared network collection code verified for macOS, iOS, and watchOS
- Compile-time tool plugins with Swift or Rust execution backends

## Project status

The macOS menu bar app remains the primary interface. Native iPhone, iPad, and Apple Watch targets now share the same registry, models, persistence, and network information tool. Cloud synchronization will be enabled after the iCloud container is provisioned.

Nearby Wi-Fi scanning uses CoreWLAN and is available on macOS. A general-purpose scanner cannot use the iOS Hotspot Helper APIs without a special Apple entitlement and an approved hotspot-integration use case.

SSH Keys uses the system OpenSSH generator. ToolPouch writes keys only to a folder explicitly selected by the user, remembers access with a security-scoped bookmark, prevents overwriting existing pairs, and requires confirmation before copying a private key.

## Requirements

- macOS 27, iOS 27, or watchOS 27
- Xcode 27 or later
- Swift 6

## Running the app

Open `toolpouch.xcodeproj` in Xcode and run the `toolpouch` scheme, or use:

```bash
./script/build_and_run.sh
```

The available schemes are `toolpouch`, `toolpouchMobile`, and `toolpouchWatch`. Left-click the macOS menu bar icon to open the compact tool grid. Right-click it to open the full app window, Settings, About, or quit the app.

The Xcode project is generated from `project.yml`. Run `xcodegen generate` after changing targets, build settings, or source membership.

## Structure

- `App` — application composition and navigation
- `Core` — shared models and contracts
- `Features` — feature-specific domain, data, and presentation code
- `Infrastructure` — persistence and future synchronization
- `Platform` — operating-system integrations
- `DesignSystem` — reusable SwiftUI components and layout values
- `Rust` — reusable high-performance engines and their FFI bindings

More details are available in [Architecture](docs/Architecture.md).
