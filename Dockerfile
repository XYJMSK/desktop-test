FROM ghcr.io/xyjmsk/claude-desktop-container:latest

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
