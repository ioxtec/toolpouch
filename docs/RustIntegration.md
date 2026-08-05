# Rust integration

## Purpose

Rust is reserved for deterministic work that benefits from high performance, strong memory safety, or reusable processing code. Swift remains responsible for the interface, permissions, persistence, security-scoped file access, and application lifecycle.

Good candidates include image processing, media conversion, archive operations, and large-file analysis. Small formatting operations and direct Apple framework integrations should normally remain in Swift.

## Boundary

The integration follows this path:

```text
ToolPlugin → Swift service → typed Swift wrapper → C ABI → Rust facade → Rust engine
```

`toolpouch-engine` is the only crate that exports C symbols. Domain crates such as `toolpouch-image` contain pure Rust logic and do not know about Swift or Apple UI frameworks.

A small C ABI was chosen because it is stable across Swift and Rust toolchains, keeps the exported surface easy to audit, and avoids coupling feature code to generated bindings.

## Data and ownership

- Pass large files as paths after Swift obtains sandbox access.
- Return fixed-layout structures or caller-owned buffers where possible.
- Document who allocates and releases every pointer that crosses the boundary.
- Never retain a Swift pointer after the exported function returns unless the API explicitly establishes a longer lifetime.
- Convert raw return codes into typed Swift errors inside the wrapper.

The first engine powers Image Toolkit. It reads image and EXIF metadata from an authorized file path, and it performs resizing and format conversion without passing decoded pixels through Swift.

## Versioning

The facade exposes an API version. Any incompatible change to a structure, symbol, or ownership rule must increment that version. Additive functions may keep the current version when older callers remain valid.

Rust panics must not cross the C boundary. Exported functions validate pointers and input lengths, catch failures where necessary, and return a documented status code.

## Long-running work

Fast operations may use synchronous calls from a background Swift task. Media conversions should use an opaque task handle with progress, cancellation, and completion callbacks. UI code must never wait for a long Rust operation on the main actor.

A future macOS XPC service may link the same library when a conversion needs crash isolation. iOS and iPadOS should link the engine directly.

## Building

The pinned toolchain is defined in `rust-toolchain.toml`. Run the Rust tests and build the Apple framework from the repository root:

```bash
cargo test --manifest-path Rust/Cargo.toml --locked
./script/build_rust.sh apple
```

The build script creates an XCFramework for macOS Apple silicon, iOS devices, and Apple-silicon iOS simulators.

watchOS is currently excluded because the pinned stable Rust toolchain does not distribute watchOS standard-library artifacts through rustup. Introduce a nightly `build-std` pipeline only when a concrete watch feature justifies its additional maintenance cost.

## Adding an engine

1. Create a pure Rust crate for the processing domain.
2. Add tests that exercise normal input, malformed input, and boundary values.
3. Add a narrow facade function to `toolpouch-engine`.
4. Update the public C header and keep its layout in sync with Rust.
5. Add a typed Swift wrapper that hides raw pointers and status codes.
6. Type-check the wrapper against the generated module and build every supported Apple target.
7. Document permissions, file access, cancellation, and data handling for the user-facing tool.
