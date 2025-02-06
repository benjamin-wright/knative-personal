FROM busybox as get

ARG ARCH=x86_64

RUN wget https://github.com/containerd/runwasi/releases/download/containerd-shim-wasmedge%2Fv0.4.0/containerd-shim-wasmedge-${ARCH}.tar.gz -O /tmp/containerd-shim-wasmedge-${ARCH}.tar.gz && \
    tar -xvf /tmp/containerd-shim-wasmedge-${ARCH}.tar.gz -C /tmp

FROM rancher/k3s:v1.32.1-k3s1

COPY --from=get /tmp/containerd-shim-wasmedge-v1 /usr/local/bin/containerd-shim-wasmedge-v1
