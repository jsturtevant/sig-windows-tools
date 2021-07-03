# note this image doesn't really mater for hostprocess
ARG BASE="mcr.microsoft.com/windows/nanoserver"
ARG cniVersion="0.8.7"
ARG flannelVersion="0.14.0"

FROM --platform=linux/amd64 curlimages/curl as bins
ARG cniVersion
ARG flannelVersion

WORKDIR /cni
RUN curl -Lo cni.tgz https://github.com/containernetworking/plugins/releases/download/v${cniVersion}/cni-plugins-windows-amd64-v${cniVersion}.tgz
RUN tar -xf cni.tgz
RUN rm cni.tgz

WORKDIR /flannel 
RUN curl -Lo flanneld.exe https://github.com/coreos/flannel/releases/download/v${flannelVersion}/flanneld.exe

FROM $BASE

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"

# wins.exe doesn't work in nanoserver with default ContainerUser.
USER ContainerAdministrator

COPY start.ps1 /flannel/start.ps1
COPY --from=bins /cni /cni
COPY start.ps1 /flannel/start.ps1
ADD https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1 /flannel/hns.psm1
COPY --from=bins /flannel/flanneld.exe /flannel/flanneld.exe

ENTRYPOINT ["PowerShell", "/c", "$env:CONTAINER_SANDBOX_MOUNT_POINT/flannel/start.ps1"]
