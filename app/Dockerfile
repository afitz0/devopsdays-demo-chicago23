FROM golang:1.20 AS builder

ARG CGO_ENABLED=0
WORKDIR ${GOPATH:-/go}/src/devopsdays

COPY . .

RUN go mod download
RUN go get -d -v ./...
RUN go build -o ${GOPATH:-/go}/bin/ ./worker

FROM gcr.io/distroless/base
COPY --from=builder ${GOPATH:-/go}/bin/worker /bin

ENTRYPOINT ["/bin/worker"]
