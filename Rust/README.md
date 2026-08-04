# ToolPouch Rust engines

This workspace contains reusable computation engines for ToolPouch. Rust crates do not own UI, navigation, file pickers, permissions, or persistence.

## Boundaries

- Swift owns platform integration and user interaction.
- Rust owns CPU-intensive, deterministic transformations.
- Public FFI functions use a versioned C ABI.
- Rust allocations never cross the FFI boundary without an explicit release function.
- Panics must not unwind across FFI calls.
- Large file operations should use input and output paths while Swift maintains security-scoped access.

## Commands

Run the Rust tests:

```bash
cargo test --manifest-path Rust/Cargo.toml
```

Build a local macOS XCFramework:

```bash
./script/build_rust.sh host
```

The generated framework is written to `.build/Rust/ToolPouchRust.xcframework` and is not committed. The `apple` mode builds all configured Apple targets after their Rust targets are installed.
