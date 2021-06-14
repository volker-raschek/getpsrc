ARG BASE_IMAGE
ARG BUILD_IMAGE

# BUILD
# =====================================================================
FROM ${BUILD_IMAGE} AS build

ARG GONOPROXY
ARG GONOSUMDB
ARG GOPRIVATE
ARG GOPROXY
ARG GOSUMDB
ARG VERSION

COPY ./ /workspace

RUN cd /workspace && \
    GONOPROXY=${GONOPROXY} \
    GONOSUMDB=${GONOSUMDB} \
    GOPRIVATE=${GOPRIVATE} \
    GOPROXY=${GOPROXY} \
    GOSUMDB=${GOSUMDB} \
    VERSION=${VERSION} \
      make all

# TARGET
# =====================================================================
FROM ${BASE_IMAGE}

COPY --from=build /workspace/getpsrc /usr/bin/getpsrc

ENTRYPOINT [ "/usr/bin/getpsrc" ]
