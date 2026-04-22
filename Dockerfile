FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NOVNC_PORT=6901
ENV VNC_PW=headless
ENV VNC_RESOLUTION=1360x768

# Install basic packages
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    git \
    curl \
    unzip \
    python3 \
    python3-pip \
    python3-numpy \
    dbus-x11 \
    xauth \
    xinit \
    x11-xserver-utils \
    xdg-utils \
    tigervnc-standalone-server \
    novnc \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install XFCE
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-terminal \
    elementary-xfce-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Create startup script
RUN mkdir -p /dockerstartup
COPY start.sh /dockerstartup/start.sh
RUN chmod +x /dockerstartup/start.sh

EXPOSE ${VNC_PORT} ${NOVNC_PORT}

CMD ["/dockerstartup/start.sh"]
