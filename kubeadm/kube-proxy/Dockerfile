# note this image doesn't really mater 
ARG BASE="mcr.microsoft.com/windows/nanoserver"
ARG k8sVersion="v1.22.0-alpha.1"

FROM --platform=linux/amd64 curlimages/curl as bins
ARG k8sVersion

WORKDIR /utils
RUN curl -Lo yq.exe https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe

WORKDIR /kube-proxy
RUN curl -sLO https://dl.k8s.io/${k8sVersion}/bin/windows/amd64/kube-proxy.exe
RUN curl -LO https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1

FROM $BASE

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"

USER ContainerUser

Add start.ps1 /kube-proxy/start.ps1
COPY --from=bins /utils /utils
COPY --from=bins /kube-proxy /kube-proxy

ENTRYPOINT ["/kube-proxy/start.ps1"] 
