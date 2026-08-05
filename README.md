# ToolPouch

ToolPouch is a native collection of small, useful tools for Apple devices. It is designed for everyday users as well as people who need more technical utilities, without making either group navigate through an overly technical interface.

The macOS menu bar app is the primary interface today. iPhone, iPad, and Apple Watch targets share the same catalog, models, and supported services, while each platform uses navigation suited to its screen.

## Available tools

| Section | Tool | macOS | iPhone / iPad | Apple Watch |
| --- | --- | :---: | :---: | :---: |
| Everyday | Unit Converter | ✓ | ✓ | ✓ |
| Network | Network Info | ✓ | ✓ | ✓ |
| Network | Network Check | ✓ | ✓ | — |
| Network | Wi-Fi Analyzer | ✓ | — | — |
| Network | WHOIS (RDAP) | ✓ | ✓ | ✓ |
| Passwords | Password Generator | ✓ | ✓ | ✓ |
| Clipboard | Clipboard Inspector | ✓ | — | — |
| Text & Files | Text Encoder | ✓ | ✓ | ✓ |
| Text & Files | JSON Toolkit | ✓ | ✓ | — |
| Text & Files | Hash & Checksum | ✓ | ✓ | — |
| Developer | SSH Keys | ✓ | — | — |
| Images & Colors | Image Toolkit (Rust) | ✓ | ✓ | — |
| Images & Colors | Color Picker | ✓ | — | — |

The catalog also provides configurable Quick Access shortcuts. Unsupported tools are filtered before navigation is rendered, so a device never presents a tool that it cannot run.

## Project status

ToolPouch is under active development. Local persistence is the default, and the data model is prepared for CloudKit synchronization after the iCloud container and production schema are configured.

The first user-facing Rust tool reads image and EXIF metadata, resizes images, and converts PNG, JPEG, and WebP files locally through a stable C interface and a typed Swift wrapper.

## Requirements

- macOS 27, iOS 27, or watchOS 27
- Xcode 27 or later
- Swift 6
- XcodeGen when changing targets or project settings
- Rust 1.92 when working on Rust engines

## Running the app

Build the local Rust framework once before generating or opening the Xcode project:

```bash
./script/build_rust.sh apple
xcodegen generate
```

Open `toolpouch.xcodeproj` in Xcode and run one of these schemes:

- `toolpouch` for macOS
- `toolpouchMobile` for iPhone and iPad
- `toolpouchWatch` for Apple Watch

The macOS app can also be built and opened with:

```bash
./script/build_and_run.sh
```

Left-click the menu bar icon to open the compact interface. Right-click it to open the application window, Settings, About, or quit ToolPouch.

The Xcode project is generated from `project.yml`. Change target membership, build settings, and platform configuration there, then run:

```bash
xcodegen generate
```

## Repository structure

- `toolpouch/App` — dependency assembly, tool registry, and app-wide navigation
- `toolpouch/Core` — shared models and tool metadata
- `toolpouch/Features` — one self-contained folder for each tool
- `toolpouch/Infrastructure` — persistence and future synchronization
- `toolpouch/Platform` — operating-system integrations
- `toolpouch/DesignSystem` — reusable SwiftUI components and visual values
- `toolpouch/Applications` — platform entry points
- `Rust` — reusable high-performance engines and Swift/C bindings
- `toolpouchTests` — domain, service, registry, and persistence tests
- `toolpouchUITests` — end-to-end interface tests

## Documentation

- [Architecture](docs/Architecture.md)
- [Development guide](docs/Development.md)
- [Adding a tool](docs/AddingATool.md)
- [Rust integration](docs/RustIntegration.md)
- [Privacy and data](docs/PrivacyAndData.md)
