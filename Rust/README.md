# ToolPouch Rust engines

This workspace contains reusable computation engines for ToolPouch. Rust crates do not own UI, navigation, file pickers, permissions, or persistence.

## Boundaries

- Swift owns platform integration and user interaction.
- Rust owns CPU-intensive, deterministic transformations.
- Public FFI functions use a versioned C ABI.
- Rust allocations never cross the FFI boundary without an explicit release function.
- Panics must not unwind across FFI calls.
- Large file operations should use input and output paths while Swift maintains security-scoped access.

## Workspace layout

- `toolpouch-engine` is the versioned C ABI facade linked by Apple targets.
- `toolpouch-image` is a pure Rust image engine with no Swift or platform UI dependencies.
- `Bindings/include` contains the stable C contract.
- `Bindings/Swift` contains typed wrappers that hide pointers and status codes.

The first production capability is image inspection. Swift grants temporary
access to a selected file and passes its UTF-8 path to Rust. Rust returns a
fixed-layout value containing dimensions, format, color model, channel depth,
alpha information, and file size. File contents and Rust allocations never
cross the FFI boundary.

Future resize, conversion, and metadata-cleaning operations belong in
`toolpouch-image`. Long-running audio and video engines should follow the same
boundary but add task handles, progress callbacks, and cancellation before
adopting FFmpeg or another media dependency.

## Commands

Run the Rust tests:

```bash
cargo test --manifest-path Rust/Cargo.toml
```

Build a local macOS XCFramework:

```bash
./script/build_rust.sh host
```

The generated framework is written to `.build/Rust/ToolPouchRust.xcframework` and is not committed. The `apple` mode builds macOS, iOS device, and iOS Simulator slices after their Rust targets are installed.

Rust-backed tools currently target macOS and iOS/iPadOS. The pinned stable Rust
toolchain recognizes watchOS triples but does not distribute their standard
libraries through rustup. watchOS features therefore remain native Swift unless
a future tool justifies maintaining a custom `build-std` pipeline.
