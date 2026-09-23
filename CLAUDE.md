# Directives for Claude

## Project goal

The goal of this project is to create a simple web proxy that allows users to use Google Cloud Documentation MCP Server without requiring authentication. This proxy will handle requests to the MCP server and authentication using Google Application Default Credentials (ADC) and then return the response to the user.

## How it works

The proxy is a simple web server that listens for incoming requests. When a request is received, `Authorization` header is added. Access token is obtained using Google Application Default Credentials (ADC) and then the request is forwarded to the MCP server. The response from the MCP server is then returned to the user.

The proxy may be run locally or deployed as a container.

## Technology Stack

- Go, standard library `net/http/httputil` reverse proxy
- `cloud.google.com/go/auth` for Google Application Default Credentials (ADC)
- Container image based on `gcr.io/distroless/static-debian13`

> Note: This project should use any available package that will make the code base shorter and is easier to maintain. That means the rule saying "no external dependencies" is not applicable here. Use any package that will make the code base shorter and easier to maintain.
