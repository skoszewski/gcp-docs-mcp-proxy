# Google Cloud Docs MCP Proxy

This repository contains a proxy for Google Cloud Documentation MCP Server.

Google required authenticated access to the MCP server, so this proxy is used to bypass that requirement and allow unauthenticated access to the documentation.

It is available using MIT license, so feel free to use it in your own projects.

## Setup

Go is required to build and run the proxy locally.

Authenticate with Google Application Default Credentials, for example:

```bash
gcloud auth application-default login
```

The Developer Knowledge API must be enabled on the target project:

```bash
gcloud services enable developerknowledge.googleapis.com --project PROJECT_ID
```

When the proxy runs using ADC authentication, it calls the MCP server as the logged-in user, so that user needs the MCP Tool User role (`roles/mcp.toolUser`, permission `mcp.tools.call`) on the target project:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="user:USER_EMAIL" --role="roles/mcp.toolUser"
```

When the proxy runs with a service account key (`--key-file` in `scripts/start.sh` and `scripts/start_container.sh`), it calls the MCP server as the service account, so the service account needs the same role:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SA_EMAIL" --role="roles/mcp.toolUser"
```

## Configuration

The proxy is configured using environment variables:

- `MCP_TARGET_URL`: MCP server endpoint to forward requests to. Defaults to `https://developerknowledge.googleapis.com/mcp`.

- `PROXY_HOST`: listen address. Defaults to `0.0.0.0`.
- `PROXY_PORT`: listen port. Defaults to `8989`.

## Running locally

```bash
go run .
```

Point your MCP client at `http://localhost:8989/`.

## Authentication diagnostics

`GET /_diagnostics/auth` reports the status of the ADC credentials used to authenticate to the MCP server: credential type, quota project, scopes, token validity and expiry, and any error encountered while refreshing the token. It does not expose the access token itself.

## Running as a container

```bash
docker build -t gcp-docs-mcp-proxy .
docker run -p 8989:8989 -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" gcp-docs-mcp-proxy
```

The image is built on `gcr.io/distroless/static-debian13`.
