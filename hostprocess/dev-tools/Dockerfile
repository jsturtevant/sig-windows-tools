ARG OS=ltsc2019
FROM mcr.microsoft.com/windows/servercore:${OS} as installer
RUN powershell /c "iwr -useb get.scoop.sh | iex"
RUN scoop install vim@8.2.2824 --global

FROM mcr.microsoft.com/windows/servercore:${OS} AS runtime
WORKDIR /apps
ENV PATH="%CONTAINER_SANDBOX_MOUNT_POINT%\apps\vim;C:\Windows\system32;C:\Windows"

COPY --from=installer /ProgramData/scoop/apps/vim/8.2.2824 ./vim/

