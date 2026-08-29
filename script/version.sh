#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_YML="$ROOT_DIR/project.yml"
XCODE_PROJECT="$ROOT_DIR/toolpouch.xcodeproj/project.pbxproj"

usage() {
    cat <<'EOF'
usage:
  ./script/version.sh show
  ./script/version.sh bump-build
  ./script/version.sh set-version MAJOR.MINOR.PATCH

Examples:
  ./script/version.sh set-version 0.2.0
  ./script/version.sh bump-build
EOF
}

read_setting() {
    local key="$1"
    awk -v key="$key" '$1 == key ":" { print $2; exit }' "$PROJECT_YML"
}

write_setting() {
    local key="$1"
    local value="$2"

    VERSION_KEY="$key" VERSION_VALUE="$value" /usr/bin/perl -0pi -e '
        s/^(\s*)\Q$ENV{VERSION_KEY}\E:\s*.*$/$1$ENV{VERSION_KEY}: $ENV{VERSION_VALUE}/m
    ' "$PROJECT_YML"

    VERSION_KEY="$key" VERSION_VALUE="$value" /usr/bin/perl -0pi -e '
        s/^(\s*)\Q$ENV{VERSION_KEY}\E\s*=\s*[^;]+;/$1$ENV{VERSION_KEY} = $ENV{VERSION_VALUE};/mg
    ' "$XCODE_PROJECT"
}

show_version() {
    printf 'ToolPouch %s (build %s)\n' \
        "$(read_setting MARKETING_VERSION)" \
        "$(read_setting CURRENT_PROJECT_VERSION)"
}

command="${1:-show}"
case "$command" in
    show)
        show_version
        ;;
    bump-build)
        current_build="$(read_setting CURRENT_PROJECT_VERSION)"
        if [[ ! "$current_build" =~ ^[0-9]+$ ]]; then
            echo "CURRENT_PROJECT_VERSION must be a positive integer." >&2
            exit 1
        fi
        next_build=$((current_build + 1))
        write_setting CURRENT_PROJECT_VERSION "$next_build"
        show_version
        ;;
    set-version)
        version="${2:-}"
        if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version must use MAJOR.MINOR.PATCH, for example 0.2.0." >&2
            exit 1
        fi
        write_setting MARKETING_VERSION "$version"
        show_version
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
