#!/bin/sh
set -e

SA_NAME="gcp-docs-mcp-proxy"
DISPLAY_NAME="GCP Docs MCP Proxy"
KEY_FILE="key.json"
PROJECT=""
LOCAL_KEY=false

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
        --display-name)
            DISPLAY_NAME="$2"
            shift 2
            ;;
        --key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        --local-key)
            LOCAL_KEY=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$PROJECT" ]; then
    echo "usage: $0 PROJECT [--sa-name NAME] [--display-name NAME] [--key-file FILE] [--local-key]" >&2
    exit 1
fi

SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT" >/dev/null 2>&1; then
    echo "Service account $SA_EMAIL already exists, skipping creation."
else
    gcloud iam service-accounts create "$SA_NAME" \
        --project "$PROJECT" \
        --display-name "$DISPLAY_NAME"
fi

BOUND=$(gcloud projects get-iam-policy "$PROJECT" \
    --flatten "bindings[].members" \
    --filter "bindings.role=roles/mcp.toolUser AND bindings.members=serviceAccount:${SA_EMAIL}" \
    --format "value(bindings.members)")

if [ -n "$BOUND" ]; then
    echo "roles/mcp.toolUser already bound to $SA_EMAIL, skipping."
else
    gcloud projects add-iam-policy-binding "$PROJECT" \
        --member "serviceAccount:${SA_EMAIL}" \
        --role "roles/mcp.toolUser"
fi

if [ -f "$KEY_FILE" ]; then
    echo "$KEY_FILE already exists, skipping key creation." >&2
    exit 0
fi

EXISTING_KEYS=$(gcloud iam service-accounts keys list \
    --iam-account "$SA_EMAIL" \
    --managed-by user \
    --format "value(name)")

if [ -n "$EXISTING_KEYS" ]; then
    echo "$SA_EMAIL has user-managed key(s) in GCP; $KEY_FILE not found locally." >&2
    echo "No key created. Existing key(s):" >&2
    echo "$EXISTING_KEYS" >&2
    exit 1
fi

if [ "$LOCAL_KEY" = true ]; then
    PRIVATE_KEY_FILE=$(mktemp)
    PUBLIC_CERT_FILE=$(mktemp)
    chmod 600 "$PRIVATE_KEY_FILE"

    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout "$PRIVATE_KEY_FILE" \
        -out "$PUBLIC_CERT_FILE" \
        -subj "/CN=${SA_NAME}/emailAddress=${SA_EMAIL}"

    KEY_NAME=$(gcloud iam service-accounts keys upload "$PUBLIC_CERT_FILE" \
        --iam-account "$SA_EMAIL" \
        --format "value(name)")
    KEY_ID=$(basename "$KEY_NAME")

    jq -n \
        --arg project_id "$PROJECT" \
        --arg private_key_id "$KEY_ID" \
        --rawfile private_key "$PRIVATE_KEY_FILE" \
        --arg client_email "$SA_EMAIL" \
        '{
            type: "service_account",
            project_id: $project_id,
            private_key_id: $private_key_id,
            private_key: $private_key,
            client_email: $client_email,
            token_uri: "https://oauth2.googleapis.com/token"
        }' > "$KEY_FILE"

    rm -f "$PRIVATE_KEY_FILE" "$PUBLIC_CERT_FILE"
else
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account "$SA_EMAIL"
fi

chmod 600 "$KEY_FILE"
