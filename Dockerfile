FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git wget unzip python3 python3-pip python3-venv sudo gnupg ca-certificates lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && node --version && npm --version

RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies xfce4-terminal \
    dbus-x11 x11-utils x11-xserver-utils fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g claude-code-best

EXPOSE 7860
ENTRYPOINT ["bash", "-c", "tail -f /dev/null"]
