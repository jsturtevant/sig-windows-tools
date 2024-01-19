ARG BASE="mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image:v0.1.0"

FROM --platform=linux/amd64 curlimages/curl as bins
ARG k8sVersion="v1.28.4"

WORKDIR /kube-proxy
RUN curl -LO https://dl.k8s.io/$k8sVersion/bin/windows/amd64/kube-proxy.exe

FROM $BASE

ENV PATH="C:\Windows\system32;C:\Windows;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;"

COPY --from=bins /kube-proxy/kube-proxy.exe /kube-proxy/kube-proxy.exe

ENTRYPOINT ["c:/hpc/kube-proxy/kube-proxy.exe"]