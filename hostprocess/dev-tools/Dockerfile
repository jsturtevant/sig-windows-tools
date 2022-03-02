ARG OS=ltsc2019
FROM mcr.microsoft.com/windows/servercore:${OS} as installer
WORKDIR /apps
RUN powershell /c "iwr -useb get.scoop.sh | iex"
RUN scoop install vim@8.2.2824 --global
RUN curl.exe -LO https://download.sysinternals.com/files/SysinternalsSuite.zip
RUN powershell /c "Expand-Archive SysinternalsSuite.Zip"


FROM mcr.microsoft.com/windows/nanoserver:1809 AS runtime
WORKDIR /apps
ENV PATH="%CONTAINER_SANDBOX_MOUNT_POINT%\apps\vim;%CONTAINER_SANDBOX_MOUNT_POINT%\apps\sysinternals;C:\Windows\system32;C:\Windows"

COPY --from=installer /ProgramData/scoop/apps/vim/8.2.2824 ./vim/
COPY --from=installer /apps/SysinternalsSuite ./sysinternals/

