FROM mcr.microsoft.com/powershell:latest

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y rsync

COPY ./entry.ps1 /entry.ps1

RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
      tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
    SUITE=$(lsb_release -cs); \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $SUITE main" | \
        tee /etc/apt/sources.list.d/microsoft.list && \
    cat << EOF | tee /etc/apt/preferences.d/99-microsoft && \
    apt-get update && apt-get install -y azure-cli;

ENTRYPOINT ["pwsh", "/entry.ps1"]
