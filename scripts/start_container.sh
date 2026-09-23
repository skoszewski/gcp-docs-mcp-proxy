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

# Detect container runtime
if command -v docker >/dev/null 2>&1; then
    RUNNER="docker"
elif command -v container >/dev/null 2>&1; then
    RUNNER="container"
else
    echo "Error: No container runtime found (docker or container required)" >&2
    exit 1
fi

# Run container based on detected runtime
case "$RUNNER" in
    docker)
        if [ -n "$KEY_FILE" ]; then
            docker run --rm --name "$NAME" -d -p "${PORT}:8989" \
                -e GOOGLE_APPLICATION_CREDENTIALS=/app/key.json \
                -v "$(realpath "$KEY_FILE"):/app/key.json" \
                "$IMAGE"
        else
            GCLOUD_CONFIG_DIR="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
            docker run --rm --name "$NAME" -d -p "${PORT}:8989" \
                -v "${GCLOUD_CONFIG_DIR}:/root/.config/gcloud:ro" \
                "$IMAGE"
        fi
        ;;
    container)
        if [ -n "$KEY_FILE" ]; then
            container run --rm --name "$NAME" -d -p "${PORT}:8989" \
                -e GOOGLE_APPLICATION_CREDENTIALS=/app/key.json \
                -v "$(realpath "$KEY_FILE"):/app/key.json" \
                "$IMAGE"
        else
            GCLOUD_CONFIG_DIR="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
            container run --rm --name "$NAME" -d -p "${PORT}:8989" \
                -v "${GCLOUD_CONFIG_DIR}:/root/.config/gcloud:ro" \
                "$IMAGE"
        fi
        ;;
    *)
        echo "Error: Unsupported container runtime: $RUNNER" >&2
        exit 1
        ;;
esac
