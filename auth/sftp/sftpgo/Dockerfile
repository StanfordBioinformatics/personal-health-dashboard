FROM drakkan/sftpgo:v2-alpine AS sftpgo

FROM golang:1.16 AS builder

WORKDIR /sftp-external-auth
ADD sftpgo/sftp-external-auth .

RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
  go build -ldflags "-w -extldflags -static" -a

# using this https://hub.docker.com/r/lsiobase/alpine
# this is just a simple alpine linux image with some init hooks for running the
# sftp server
FROM lsiobase/alpine:3.13

# install necessary packages
RUN apk add py-pip musl fail2ban

# all logs go here
RUN mkdir -p /logs

# get everything ready for sftpgo
RUN mkdir -p /config/sftpgo
COPY --from=sftpgo /usr/local/bin/sftpgo /config/sftpgo/sftpgo
COPY sftpgo/sftpgo.json /config/sftpgo/sftpgo.json
COPY --from=builder /sftp-external-auth/sftp_external_auth /config/sftpgo

# copy services to run
RUN mkdir -p /etc/services.d/sftpgo
RUN mkdir -p /etc/services.d/logtail
COPY config/services.d/sftpgo/run /etc/services.d/sftpgo/run
COPY config/services.d/logtail/run /etc/services.d/logtail/run

# sftpgo env variables
ENV SFTPGO_CONFIG_DIR /config/sftpgo
ENV SFTPGO_CONFIG_FILE sftpgo
ENV SFTPGO_LOG_COMPRESS true
ENV SFTPGO_LOG_FILE_PATH /logs/sftpgo.log
ENV SFTPGO_LOG_MAX_AGE 28
ENV SFTPGO_LOG_MAX_BACKUPS 5
ENV SFTPGO_LOG_MAX_SIZE 100
ENV SFTPGO_LOG_VERBOSE true

# user env variables
ENV PUID 100
ENV PGID 100

# dir env variables
ENV LOGS_DIR /logs
ENV KEYS_DIR /mnt/keys
ENV SECRETS_DIR /secrets
ENV PAYLOAD_BASE_DIR /opt
ENV CREDENTIALS_DIR /credentials

# other helper directories
RUN mkdir -p /opt
RUN mkdir -p /credentials

# Setup fail2ban
ENV CONSOLIDATED_FAILED_AUTH_LOGFILE /logs/fail2ban/failed_auth.log
COPY config/init_scripts/fail2ban-init /etc/cont-init.d/fail2ban-init
RUN rm /etc/fail2ban/jail.conf
RUN rm -rf /etc/fail2ban/jail.d
COPY config/fail2ban /etc/fail2ban

# this is the default directory when we exec into the container
WORKDIR /config
