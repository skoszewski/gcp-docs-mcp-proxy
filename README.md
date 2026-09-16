# Google Cloud Docs MCP Proxy

This repository contains a proxy for Google Cloud Documentation MCP Server.

Google required authenticated access to the MCP server, so this proxy is used to bypass that requirement and allow unauthenticated access to the documentation.

It is available using MIT license, so feel free to use it in your own projects.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Authenticate with Google Application Default Credentials, for example:

```bash
gcloud auth application-default login
```

The Developer Knowledge API must be enabled on the target project:

```bash
gcloud services enable developerknowledge.googleapis.com --project PROJECT_ID
```

## Configuration

The proxy is configured using environment variables:

- `MCP_TARGET_URL`: MCP server endpoint to forward requests to. Defaults to `https://developerknowledge.googleapis.com/mcp`.

The listen address and port are controlled by uvicorn's command-line flags.

## Running locally

```bash
source .venv/bin/activate
uvicorn proxy:app --host 0.0.0.0 --port 8989
```

Point your MCP client at `http://localhost:8989/`.

## Authentication diagnostics

`GET /_diagnostics/auth` reports the status of the ADC credentials used to authenticate to the MCP server: credential type, quota project, scopes, token validity and expiry, and any error encountered while refreshing the token. It does not expose the access token itself.

## Running as a container

```bash
docker build -t gcp-docs-mcp-proxy .
docker run -p 8989:8989 -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" gcp-docs-mcp-proxy
```
