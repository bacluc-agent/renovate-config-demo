#!/bin/bash

# renovate: datasource=docker depName=renovate/renovate
RENOVATE_VERSION="44.115.13"

set -euo pipefail

SCRIPT_DIR=$(realpath $(dirname $0))
REPO_ROOT=$(dirname $SCRIPT_DIR)
SNAPSHOT_FILE="$REPO_ROOT/.github/renovate-snapshot.json"

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --check      Check if snapshot is valid (CI mode)"
    echo "  --update     Update snapshot from Renovate output"
    echo "  --help       Show this help"
}

generate_snapshot() {
    docker run --rm -e LOG_LEVEL=debug -e LOG_FORMAT=json -v "$REPO_ROOT:/workspace" -w /workspace renovate/renovate:${RENOVATE_VERSION} --platform=local 2>/tmp/renovate-err.log | jq -s \
        '(first(.[] | select(.msg == "packageFiles with updates")).config // {}) | [ .[] | .[] | . as $pf | .deps[] | select(has("depName") and has("currentValue")) | {file: $pf.packageFile, depName: .depName, currentValue: .currentValue}] | sort_by(.file, .depName)' \
        | jq 'map(select(.file | startswith(".github/workflows/") | not))'
}

expect_pairs() {
    local rc=0
    local pair file dep
    local pairs=(
        "versions.yaml|ghcr.io/bacluc/prettier-image/prettier-image"
        "scripts/install.sh|opencode-ai"
        "Dockerfile|alpine"
        "scripts/update-renovate-snapshot.sh|renovate/renovate"
    )
    for pair in "${pairs[@]}"; do
        file="${pair%%|*}"
        dep="${pair#*|}"
        if ! jq -e --arg f "$file" --arg d "$dep" 'any(.[]; .file == $f and .depName == $d)' "$SNAPSHOT_FILE" >/dev/null; then
            echo "MISSING expected (file, depName) pair: $file, $dep" >&2
            rc=1
        fi
    done
    return $rc
}

write_snapshot() {
    local tmp
    tmp=$(mktemp)
    generate_snapshot > "$tmp"
    mv "$tmp" "$SNAPSHOT_FILE"
    jq -r '.[] | "\(.file): \(.depName)@\(.currentValue)"' "$SNAPSHOT_FILE"
}

check_snapshot() {
    write_snapshot
    expect_pairs
    git diff --exit-code "$SNAPSHOT_FILE"
}

case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --check|--ci)
        check_snapshot
        exit $?
        ;;
    --update|-u)
        write_snapshot
        expect_pairs
        ;;
    "")
        echo -e "No option specified. Use --help for usage."
        exit 1
        ;;
    *)
        echo -e "Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
