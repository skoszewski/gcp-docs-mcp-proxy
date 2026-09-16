#!/bin/sh
set -e

HOST="${PROXY_HOST:-0.0.0.0}"
PORT="${PROXY_PORT:-8989}"

if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    jq -r '"Auth: service account key (\(.client_email))"' "$GOOGLE_APPLICATION_CREDENTIALS"
else
    echo "Auth: ADC"
fi

echo "Starting gcp-docs-mcp-proxy on ${HOST}:${PORT}"

uvicorn proxy:app --host "$HOST" --port "$PORT" &
UVICORN_PID=$!

trap 'echo "Received shutdown signal, stopping uvicorn (pid $UVICORN_PID)"; kill -TERM "$UVICORN_PID"; wait "$UVICORN_PID"' TERM INT

wait "$UVICORN_PID"
echo "uvicorn exited"
