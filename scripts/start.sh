#!/bin/sh
set -e

HOST="0.0.0.0"
PORT="8989"
KEY_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --host)
            HOST="$2"
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

cd "$(dirname "$0")/.."
. .venv/bin/activate

if [ -n "$KEY_FILE" ]; then
    GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
    export GOOGLE_APPLICATION_CREDENTIALS
fi

if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    jq -r '"Auth: service account key (\(.client_email))"' "$GOOGLE_APPLICATION_CREDENTIALS"
else
    echo "Auth: ADC"
fi

exec uvicorn proxy:app --host "$HOST" --port "$PORT"
