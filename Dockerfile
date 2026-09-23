FROM golang:1.27 AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY main.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /proxy .

FROM gcr.io/distroless/static-debian13

COPY --from=build /proxy /proxy

EXPOSE 8989

ENTRYPOINT ["/proxy"]
