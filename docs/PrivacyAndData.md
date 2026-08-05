# Privacy and data

ToolPouch should process data on the device whenever a feature does not require an external source. Tools must request only the access they need, at the moment the user starts the relevant action.

## Local processing

- Passwords and passphrases are generated locally and are not stored by ToolPouch.
- Text encoding, JSON formatting, hashing, checksums, and unit conversion run locally.
- Clipboard Inspector reads the macOS pasteboard while its screen is active and can clear it on request. Clipboard contents are not persisted or synchronized.
- SSH Keys reads only the folder selected by the user. Access is remembered with a security-scoped bookmark. Private key contents are not persisted, and copying a private key requires explicit confirmation.
- Rust engines receive sandbox-authorized file paths and process files locally.
- Color Picker captures only a small area around the pointer while its picking mode is active. The sampled pixels and selected color are not persisted or uploaded.

## Network requests

- Network Info contacts the configured public IP endpoint to discover the device's outward-facing address. Local interface, router, and DNS information comes from the operating system.
- WHOIS uses the public RDAP protocol. The queried domain is sent to the relevant RDAP service, and the raw JSON response can be viewed or saved by the user.
- Network Check contacts only the host entered by the user for the selected check.
- Wi-Fi Analyzer uses macOS system frameworks and location authorization to read nearby network details. It does not upload scan results.

Every external service should be replaceable behind a domain protocol. Network code must use secure transport, validate responses, and present failures without exposing internal implementation details.

## Persistence and synchronization

Network snapshots and device metadata are stored through SwiftData. Local storage is the development default. The schema is prepared for private CloudKit synchronization, but synchronization is not considered active until the iCloud container, entitlements, and production schema are configured and verified.

Sensitive transient values such as generated passwords, clipboard contents, private keys, and file contents must not be added to CloudKit records, analytics, or logs.

## Adding permissions or data collection

Before a feature requests a new permission or sends data away from the device:

1. Keep the request tied to a clear user action.
2. Explain why the access is needed before the system prompt appears.
3. Define what is stored, where it is stored, and how it can be removed.
4. Update this document, the platform privacy descriptions, and the release privacy information.
5. Add tests for denied permission and unavailable service states.
