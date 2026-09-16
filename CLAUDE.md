# Directives for Claude

## Project goal

The goal of this project is to create a simple web proxy that allows users to use Google Cloud Documentation MCP Server without requiring authentication. This proxy will handle requests to the MCP server and authentication using Google Application Default Credentials (ADC) and then return the response to the user.

## How it works

The proxy is a simple web server that listens for incoming requests. When a request is received, `Authorization` header is added. Access token is obtained using Google Application Default Credentials (ADC) and then the request is forwarded to the MCP server. The response from the MCP server is then returned to the user.

The proxy may be run locally or deployed as a container.

## Technology Stack

- Python 3 version 3.12 or higher

## Python Virtual Environment

The virtual environment is in `.venv` folder of the project root. To activate it, run the following command:

```bash
source .venv/bin/activate
```

The virtual environment is created using:

```bash
python3 -m venv .venv
```

The virtual environment is excluded from the repository using `.gitignore` file.
