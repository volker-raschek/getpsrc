FROM docker.io/library/golang:1.22.3-alpine3.18 as build

ARG VERSION

COPY ./ /workspace

WORKDIR /workspace

RUN set -ex && \
    apk update && \
    apk add git make && \
    make all VERSION=${VERSION}

# TARGET
# =====================================================================
FROM docker.io/library/alpine:3.19

ARG VERSION=latest

LABEL org.opencontainers.image.authors="Markus Pesch" \
      org.opencontainers.image.description="Return the ip address of the router to forward traffic to an external ip address" \
      org.opencontainers.image.documentation="https://git.cryptic.systems/volker.raschek/getpsrc#getpsrc" \
      org.opencontainers.image.title="getpsrc" \
      org.opencontainers.image.vendor="Markus Pesch" \
      org.opencontainers.image.version="${VERSION}"

COPY --from=build /workspace/getpsrc /usr/bin/getpsrc

ENTRYPOINT [ "/usr/bin/getpsrc" ]
