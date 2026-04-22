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
    && rm -rf /var/lib/apt/lists/*

# Install XFCE
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-terminal \
    elementary-xfce-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Install TigerVNC
RUN wget -q https://sourceforge.net/projects/tigervnc/files/stable/1.13.1/tigervnc-1.13.1.ubuntu22.04.x86_64.tar.gz -O /tmp/tigervnc.tar.gz \
    && tar xzf /tmp/tigervnc.tar.gz -C /usr --strip 1 \
    && rm /tmp/tigervnc.tar.gz

# Install noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz -O /tmp/novnc.tar.gz \
    && tar xzf /tmp/novnc.tar.gz -C /usr/libexec --strip 1 \
    && mv /usr/libexec/noVNC /usr/libexec/noVNCdim \
    && rm /tmp/novnc.tar.gz

RUN wget -q https://github.com/novnc/websockify/archive/v0.11.0.tar.gz -O /tmp/websockify.tar.gz \
    && tar xzf /tmp/websockify.tar.gz -C /usr/libexec/noVNCdim/utils --strip 1 \
    && rm /tmp/websockify.tar.gz

# Create startup script
RUN mkdir -p /dockerstartup
COPY start.sh /dockerstartup/start.sh
RUN chmod +x /dockerstartup/start.sh

EXPOSE ${VNC_PORT} ${NOVNC_PORT}

CMD ["/dockerstartup/start.sh"]
