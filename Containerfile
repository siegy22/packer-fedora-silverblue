FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS builder
ADD --chown=107:107 artifacts/fedora-silverblue /disk/disk.qcow2
RUN chmod 0440 /disk/*

FROM scratch
COPY --from=builder /disk/* /disk/
