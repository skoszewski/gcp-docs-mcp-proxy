#!/bin/sh
set -e

IMAGE="gcp-docs-mcp-proxy"

while [ $# -gt 0 ]; do
    case "$1" in
        --image)
            IMAGE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

cd "$(dirname "$0")/.."
container build -t "$IMAGE" .
