"""Unauthenticated reverse proxy for the Google Cloud Documentation MCP server.

Adds a Google Application Default Credentials (ADC) access token to every
forwarded request so that clients do not need their own Google credentials.
"""

import os

import google.auth
import google.auth.transport.requests
import requests
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from starlette.concurrency import run_in_threadpool

SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]
TARGET_URL = os.environ.get("MCP_TARGET_URL", "https://developerknowledge.googleapis.com/mcp")
CHUNK_SIZE = 65536

HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "host",
    "authorization",
    "content-length",
    "server",
    "date",
}

app = FastAPI()

_credentials, _ = google.auth.default(scopes=SCOPES)
_auth_request = google.auth.transport.requests.Request()
_session = requests.Session()


def get_access_token():
    if not _credentials.valid:
        _credentials.refresh(_auth_request)
    return _credentials.token


@app.get("/_diagnostics/auth")
async def auth_diagnostics():
    error = None
    try:
        await run_in_threadpool(get_access_token)
    except Exception as exc:
        error = str(exc)

    return {
        "credentials_type": type(_credentials).__name__,
        "quota_project_id": _credentials.quota_project_id,
        "scopes": list(_credentials.scopes) if _credentials.scopes else None,
        "token_valid": _credentials.valid,
        "token_expiry": _credentials.expiry.isoformat() if _credentials.expiry else None,
        "refresh_error": error,
    }


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def proxy(path: str, request: Request):
    body = await request.body()
    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }
    headers["Authorization"] = f"Bearer {await run_in_threadpool(get_access_token)}"
    if _credentials.quota_project_id:
        headers["X-Goog-User-Project"] = _credentials.quota_project_id

    response = await run_in_threadpool(
        _session.request,
        request.method,
        TARGET_URL,
        data=body,
        headers=headers,
        stream=True,
    )

    response_headers = {
        key: value
        for key, value in response.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }

    return StreamingResponse(
        response.iter_content(chunk_size=CHUNK_SIZE),
        status_code=response.status_code,
        headers=response_headers,
    )
