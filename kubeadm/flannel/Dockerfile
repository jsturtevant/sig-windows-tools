# note this image doesn't really mater for hostprocess
ARG BASE="mcr.microsoft.com/windows/nanoserver"
ARG cniVersion="0.2.0"
ARG flannelVersion="0.13.0"

FROM --platform=linux/amd64 curlimages/curl as bins
ARG cniVersion
ARG flannelVersion

WORKDIR /cni
RUN curl -Lo cni.zip https://github.com/microsoft/windows-container-networking/releases/download/v${cniVersion}/windows-container-networking-cni-amd64-v${cniVersion}.zip

WORKDIR /flannel 
RUN curl -Lo flanneld.exe https://testgridjs.blob.core.windows.net/containerd/flanneld.exe

FROM $BASE

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"

# wins.exe doesn't work in nanoserver with default ContainerUser.
USER ContainerAdministrator

ADD https://raw.githubusercontent.com/microsoft/SDN/master/Kubernetes/windows/hns.psm1 /flannel/hns.psm1
COPY start.ps1 /flannel/start.ps1
COPY --from=bins /cni /cni
COPY --from=bins /flannel/flanneld.exe /flannel/flanneld.exe

ENTRYPOINT ["PowerShell", "/c", "$env:CONTAINER_SANDBOX_MOUNT_POINT/flannel/start.ps1"]
