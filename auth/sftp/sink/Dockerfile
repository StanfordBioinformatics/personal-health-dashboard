FROM golang:1.15 AS builder
WORKDIR "${GOPATH}/src/github.com/StanfordBioinformatics/PHD-Authentication/sftp/app/sink"
COPY . .
RUN go mod download \
  && CGO_ENABLED=0 GOOS=linux go build -o sink.bin

FROM alpine:latest
RUN apk update \
  && apk add ca-certificates build-base \
  && rm -rf /var/cache/apk/*
ENV CONSOLIDATED_FAILED_AUTH_LOGFILE /logs/fail2ban/failed_auth.log
WORKDIR /app
COPY --from=builder /go/src/github.com/StanfordBioinformatics/PHD-Authentication/sftp/app/sink/sink.bin /app/
ENTRYPOINT ["./sink.bin"]