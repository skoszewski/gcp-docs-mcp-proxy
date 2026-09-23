// Unauthenticated reverse proxy for the Google Cloud Documentation MCP server.
//
// Adds a Google Application Default Credentials (ADC) access token to every
// forwarded request so that clients do not need their own Google credentials.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cloud.google.com/go/auth"
	"cloud.google.com/go/auth/credentials"
)

var scopes = []string{"https://www.googleapis.com/auth/cloud-platform"}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// authTransport adds the ADC bearer token and quota project to outgoing requests.
type authTransport struct {
	creds *auth.Credentials
	base  http.RoundTripper
}

func (t authTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	token, err := t.creds.Token(req.Context())
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token.Value)
	if quota, err := t.creds.QuotaProjectID(req.Context()); err == nil && quota != "" {
		req.Header.Set("X-Goog-User-Project", quota)
	}
	return t.base.RoundTrip(req)
}

func main() {
	target, err := url.Parse(getenv("MCP_TARGET_URL", "https://developerknowledge.googleapis.com/mcp"))
	if err != nil {
		log.Fatalf("invalid MCP_TARGET_URL: %v", err)
	}

	creds, err := credentials.DetectDefault(&credentials.DetectOptions{Scopes: scopes})
	if err != nil {
		log.Fatalf("cannot detect Application Default Credentials: %v", err)
	}

	credsType := "compute_engine"
	var credsInfo struct {
		Type        string `json:"type"`
		ClientEmail string `json:"client_email"`
	}
	if json.Unmarshal(creds.JSON(), &credsInfo) == nil && credsInfo.Type != "" {
		credsType = credsInfo.Type
	}
	if credsType == "service_account" {
		log.Printf("Auth: service account key (%s)", credsInfo.ClientEmail)
	} else {
		log.Printf("Auth: ADC (%s)", credsType)
	}

	mux := http.NewServeMux()

	// Report the state of the ADC credentials without exposing the token.
	mux.HandleFunc("GET /_diagnostics/auth", func(w http.ResponseWriter, r *http.Request) {
		result := map[string]any{
			"credentials_type": credsType,
			"scopes":           scopes,
			"token_valid":      false,
			"token_expiry":     nil,
			"refresh_error":    nil,
		}
		if quota, err := creds.QuotaProjectID(r.Context()); err == nil && quota != "" {
			result["quota_project_id"] = quota
		} else {
			result["quota_project_id"] = nil
		}
		if token, err := creds.Token(r.Context()); err != nil {
			result["refresh_error"] = err.Error()
		} else {
			result["token_valid"] = token.IsValid()
			if !token.Expiry.IsZero() {
				result["token_expiry"] = token.Expiry.Format(time.RFC3339)
			}
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(result)
	})

	mux.Handle("/", &httputil.ReverseProxy{
		Rewrite: func(pr *httputil.ProxyRequest) {
			pr.Out.URL = target
			pr.Out.Host = target.Host
		},
		Transport: authTransport{creds: creds, base: http.DefaultTransport},
		// Flush immediately so streamed (SSE) responses are not buffered.
		FlushInterval: -1,
		ModifyResponse: func(resp *http.Response) error {
			resp.Header.Del("Server")
			resp.Header.Del("Date")
			return nil
		},
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			log.Printf("proxy error: %v", err)
			http.Error(w, err.Error(), http.StatusBadGateway)
		},
	})

	server := &http.Server{
		Addr:              net.JoinHostPort(getenv("PROXY_HOST", "0.0.0.0"), getenv("PROXY_PORT", "8989")),
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		<-ctx.Done()
		log.Print("Received shutdown signal, stopping")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		server.Shutdown(shutdownCtx)
	}()

	log.Printf("Starting gcp-docs-mcp-proxy on %s", server.Addr)
	if err := server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}
