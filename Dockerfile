# ================================================================
# Desktop Test: Simple Ubuntu + XFCE + TigerVNC + noVNC
# Port: 7860 (required by ModelScope)
# ================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
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
    xfce4 \
    xfce4-terminal \
    elementary-xfce-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Create startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 7860
CMD ["/start.sh"]
