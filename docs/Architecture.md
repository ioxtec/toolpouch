# Architecture

ToolPouch uses feature-first source organization with a small shared core.

## Layers

- `App` owns composition and navigation.
- `Core` contains platform-independent value types and contracts.
- `Features` groups domain, data, and presentation code by tool.
- `Infrastructure` implements shared persistence and synchronization concerns.
- `Platform` contains operating-system integrations such as network discovery and the pasteboard.
- `DesignSystem` contains reusable visual components and layout tokens.
- `Applications` contains one entry point for each platform target.

Views depend on domain contracts rather than concrete collectors or repositories. Platform implementations are assembled in `AppDependencies`, which keeps system APIs out of feature presentation code.

## Tool plugins

`ToolRegistry` is the single source of truth for available tools. Each compile-time `ToolPlugin` provides its metadata and creates its destination view. Section screens and navigation work only with the registry, so adding a tool does not require feature-specific conditions in shared UI.

`ToolDefinition` declares supported platforms and whether its computation backend is native Swift or Rust. Plugins ship inside the signed application bundle; ToolPouch does not download or load executable code at runtime.

The registry filters both sections and tools for the current platform. Unsupported capabilities never reach navigation, which keeps platform policy out of individual views.

## Navigation shells

`CompactToolNavigationView` implements the sections → tools → tool flow used by the macOS menu bar, iPhone, and Apple Watch. The mobile toolbar always provides a direct route home after entering a section.

`ThreeColumnToolNavigationView` implements the section sidebar, tool list, and detail layout used by iPad and the optional full macOS window. Both shells resolve destinations through the same registry and preserve feature ownership.

## Wi-Fi scanning

`WiFiScanning` isolates discovery from presentation. The macOS implementation uses CoreWLAN and returns normalized domain values, while Core Location authorization is requested only when the user opens the scanner.

The plugin is registered only for macOS. iOS can expose scan lists only to approved hotspot-helper use cases through restricted Network Extension entitlements, and watchOS has no general-purpose nearby Wi-Fi scanning API.

## SSH key storage

The SSH Keys plugin is macOS-only. `SecurityScopedSSHKeyFolderStore` uses `NSOpenPanel` as the narrow AppKit boundary and persists an app-scoped security bookmark. Every read or write operation resolves the bookmark and brackets access with `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()`.

`SystemSSHKeyManager` generates keys with the system OpenSSH implementation in the app's temporary container. Swift then copies the completed private and public files into the selected folder and applies `0600` and `0644` permissions. Existing files are never overwritten. Private key contents are read only after explicit confirmation and are not persisted by ToolPouch.

## Rust engines

The `Rust` workspace contains deterministic, CPU-intensive engines. Swift continues to own UI, permissions, persistence, security-scoped file access, and platform lifecycle.

Rust exposes a small versioned C ABI from `toolpouch-engine`. `script/build_rust.sh` builds static libraries into an XCFramework. Swift-facing wrappers live beside the C headers in `Rust/Bindings` and are added to an app target when the first Rust-backed plugin is introduced.

For expensive macOS operations that need crash isolation, a future XPC service can link the same Rust library. iOS and watchOS targets link the library directly.

## Network snapshots

Every network refresh creates an immutable `NetworkInfoSnapshot`. The snapshot includes a stable device identifier, allowing macOS to display the latest information collected by each device without coupling the feature to a specific platform.

`NetworkSnapshotRecord` stores only CloudKit-compatible scalar values. Collections are encoded as `Data`, and enum values are persisted as strings so future enum cases remain migration-safe.

## CloudKit activation

The schema and entitlement file are prepared for the `iCloud.com.hoxim.toolpouch` container. Local persistence remains the default during development. After the latest Apple Developer Program License Agreement is accepted, create the container, attach `toolpouch/toolpouch.entitlements` to the target, switch the storage mode in `ToolPouchApp` from `.local` to `.cloudKitAutomatic`, and verify the production schema before release.

## Platform targets

The generated Xcode project contains macOS, iOS/iPadOS, and watchOS application targets. They reuse `NetworkInfoSnapshot`, `NetworkInfoCollecting`, and `NetworkSnapshotStoring`; platform folders contain lifecycle and system-specific integrations. Target definitions and source exclusions live in `project.yml` so adding a platform does not require manual project-file editing.
