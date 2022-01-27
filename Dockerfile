FROM gcr.io/distroless/static
ARG TARGETOS
ARG TARGETARCH
COPY bin/welcome-${TARGETOS}-${TARGETARCH} /bin/welcome

# Run as UID for nobody
USER 65534

ENTRYPOINT ["/bin/welcome"]