#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-host}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_PATH="$ROOT_DIR/Rust/Cargo.toml"
HEADERS_PATH="$ROOT_DIR/Rust/Bindings/include"
OUTPUT_DIR="$ROOT_DIR/.build/Rust"
XCFRAMEWORK_PATH="$OUTPUT_DIR/ToolPouchRust.xcframework"

if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode-beta.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
fi

targets=()
sdks=()

case "$MODE" in
    host)
        targets+=("aarch64-apple-darwin")
        sdks+=("macosx")
        ;;
    apple)
        targets+=(
            "aarch64-apple-darwin"
            "aarch64-apple-ios"
            "aarch64-apple-ios-sim"
        )
        sdks+=("macosx" "iphoneos" "iphonesimulator")
        ;;
    *)
        echo "usage: $0 [host|apple]" >&2
        exit 2
        ;;
esac

installed_targets="$(rustup target list --installed)"
for target in "${targets[@]}"; do
    if ! grep -qx "$target" <<< "$installed_targets"; then
        echo "missing Rust target: $target" >&2
        echo "install it with: rustup target add $target" >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"
libraries=()

for index in "${!targets[@]}"; do
    target="${targets[$index]}"
    sdk="${sdks[$index]}"
    sdk_root="$(xcrun --sdk "$sdk" --show-sdk-path)"

    SDKROOT="$sdk_root" cargo build \
        --manifest-path "$MANIFEST_PATH" \
        --package toolpouch-engine \
        --release \
        --locked \
        --target "$target"

    libraries+=(
        -library "$ROOT_DIR/Rust/target/$target/release/libtoolpouch_engine.a"
        -headers "$HEADERS_PATH"
    )
done

if [[ -e "$XCFRAMEWORK_PATH" ]]; then
    /bin/rm -rf "$XCFRAMEWORK_PATH"
fi

xcodebuild -create-xcframework \
    "${libraries[@]}" \
    -output "$XCFRAMEWORK_PATH"

echo "$XCFRAMEWORK_PATH"
