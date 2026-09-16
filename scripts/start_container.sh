#!/bin/sh
set -e

IMAGE="gcp-docs-mcp-proxy"
NAME="gcp-docs-mcp-proxy"
PORT="8989"
KEY_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [ -n "$KEY_FILE" ]; then
    container run --name "$NAME" -d -p "${PORT}:8989" \
        -e GOOGLE_APPLICATION_CREDENTIALS=/app/key.json \
        -v "$(realpath "$KEY_FILE"):/app/key.json" \
        "$IMAGE"
else
    GCLOUD_CONFIG_DIR="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
    container run --name "$NAME" -d -p "${PORT}:8989" \
        -v "${GCLOUD_CONFIG_DIR}:/root/.config/gcloud:ro" \
        "$IMAGE"
fi
