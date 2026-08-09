# Toolpouch Plugin SDK

This directory documents the public plugin package contract. A distributable
plugin is a ZIP archive with the `.toolpouchplugin` extension. Its root contains
`manifest.json`; executable or WebAssembly payloads live below `payload/`.

The package format is language-neutral. Toolpouch reads JSON and talks to a
plugin host protocol, so native-process plugins may be implemented in Rust,
Swift, or any language that can read and write the protocol messages.

## Choose the right plugin type

### Bundled Swift plugin

Use the app's `ToolPlugin` protocol when the plugin is developed in the main
Toolpouch repository and ships as part of the application. A bundled plugin can
construct arbitrary SwiftUI and receives typed `AppDependencies`. It is not
installable after the app has been built.

### External Swift plugin

The App Store build cannot download and execute a standalone Swift binary.
Swift plugins are therefore bundled with Toolpouch and reviewed as part of an
app release. A future directly distributed macOS build may support signed and
notarized Swift executables through the reserved `nativeProcess` runtime.

### External Rust plugin

For the App Store build, Rust plugins compile to WebAssembly and use the
`webAssembly` runtime. This keeps downloaded code behind a host-controlled API
instead of exposing native macOS frameworks.

A future directly distributed build may additionally use:

- `nativeProcess` for a standalone macOS executable, or
- `webAssembly` for the same portable payload as the App Store build.

Rust code should never rely on Swift ABI. The manifest, JSON values, and host
protocol are the compatibility boundary.

## App Store boundary

The App Store installation policy accepts `webAssembly` and `remoteService`
packages, but rejects `nativeProcess`. Downloaded plugins must remain within
Toolpouch's advertised purpose and follow App Review Guideline 4.7. In
particular, the repository needs an index with universal links, reporting and
blocking controls, age-rating metadata, and explicit consent before a plugin
receives user data or privacy permissions.

## Package layout

```text
example.toolpouchplugin/
├── manifest.json
├── payload/
│   └── macos-arm64/
│       └── plugin
├── resources/
│   └── icon.png
└── signature.json       # added by the signing workflow
```

Entry points must be relative paths below `payload/`. Absolute paths,
backslashes, empty components, `.` and `..` are rejected.

## Manifest concepts

- `schemaVersion` versions the JSON structure.
- `version` is the plugin's semantic release version.
- `minimumHostVersion` is the oldest Toolpouch release supported by the plugin.
- `runtime` tells Toolpouch how to execute the payload; it does not identify the
  source language.
- `permissions` declare security-sensitive access the user may grant.
- `requiredCapabilities` describe features the device must physically or
  technically provide.
- `tools` lists one or more tools exposed by the same package and signature.

Plugin and tool identifiers use a reverse-DNS namespace owned by the author.
For a plugin named `dev.example.formatter`, valid tools include
`dev.example.formatter` and `dev.example.formatter.text`.

See [`manifest.schema.json`](manifest.schema.json) for the complete machine-
readable contract and [`Examples/native-process/manifest.json`](Examples/native-process/manifest.json)
for a minimal native-process package.

## Current milestone

Toolpouch can decode and validate manifests, safely extract local plugin
archives, install immutable versions through a staging area, switch the active
version, roll back, and uninstall packages. Cryptographic signature
verification, WebAssembly execution, the host protocol, and the publishing CLI
will be added in later milestones. Do not treat an unsigned package as trusted
merely because its manifest passes validation.

## Local installation and trust

The installer uses a private staging directory and only moves a complete
version into the plugin store after archive, manifest, payload, and trust checks
pass. Installed versions are immutable. Activation changes a small atomic
pointer, which also makes rollback independent from package extraction.

The default production policy rejects unsigned packages. During development,
Toolpouch may explicitly use `PluginInstallationPolicy.localDevelopment`; such
installs are recorded as `unsignedLocal` and must be clearly identified in UI.
Do not enable this policy silently for repository downloads.
