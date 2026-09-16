#!/bin/sh
set -e

cd "$(dirname "$0")"
. .venv/bin/activate
exec uvicorn proxy:app --host 0.0.0.0 --port 8989
