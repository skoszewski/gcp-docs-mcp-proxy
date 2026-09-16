#!/bin/sh
set -e

SA_NAME="gcp-docs-mcp-proxy"
KEY_FILE="key.json"
PROJECT=""

if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
    PROJECT="$1"
    shift
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --sa-name)
            SA_NAME="$2"
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

if [ -z "$PROJECT" ]; then
    echo "usage: $0 PROJECT [--sa-name NAME] [--key-file FILE]" >&2
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Key file not found: $KEY_FILE" >&2
    exit 1
fi

SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"
KEY_ID=$(jq -r '.private_key_id' "$KEY_FILE")

gcloud iam service-accounts keys delete "$KEY_ID" \
    --project "$PROJECT" \
    --iam-account "$SA_EMAIL" \
    --quiet

rm -f "$KEY_FILE"
