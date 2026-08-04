# Architecture

ToolPouch uses feature-first source organization with a small shared core.

## Layers

- `App` owns composition and navigation.
- `Core` contains platform-independent value types and contracts.
- `Features` groups domain, data, and presentation code by tool.
- `Infrastructure` implements shared persistence and synchronization concerns.
- `Platform` contains operating-system integrations such as network discovery and the pasteboard.
- `DesignSystem` contains reusable visual components and layout tokens.

Views depend on domain contracts rather than concrete collectors or repositories. Platform implementations are assembled in `AppDependencies`, which keeps system APIs out of feature presentation code.

## Network snapshots

Every network refresh creates an immutable `NetworkInfoSnapshot`. The snapshot includes a stable device identifier, allowing macOS to display the latest information collected by each device without coupling the feature to a specific platform.

`NetworkSnapshotRecord` stores only CloudKit-compatible scalar values. Collections are encoded as `Data`, and enum values are persisted as strings so future enum cases remain migration-safe.

## CloudKit activation

The schema and entitlement file are prepared for the `iCloud.com.hoxim.toolpouch` container. Local persistence remains the default during development. After the latest Apple Developer Program License Agreement is accepted, create the container, attach `toolpouch/toolpouch.entitlements` to the target, switch the storage mode in `ToolPouchApp` from `.local` to `.cloudKitAutomatic`, and verify the production schema before release.

## Adding a platform

New platform targets should reuse `NetworkInfoSnapshot`, `NetworkInfoCollecting`, and `NetworkSnapshotStoring`. Each target provides its own `LocalNetworkInfoProviding` implementation when the available system APIs differ. UI remains platform-specific and reads the same persisted snapshots.
