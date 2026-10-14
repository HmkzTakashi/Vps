
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh
ENV RDP_USER=desktop

RUN apt-get -o Acquire::Retries=5 update && \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    xrdp xorgxrdp \
    dbus-x11 \
    tigervnc-standalone-server \
    novnc websockify \
    sudo curl wget git vim \
    ca-certificates tzdata \
    net-tools xterm \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# Create desktop user and configure XFCE
RUN useradd -m -s /bin/bash desktop && \
    echo "desktop ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/desktop && \
    chmod 0440 /etc/sudoers.d/desktop && \
    echo "startxfce4" > /home/desktop/.xsession && \
    chown desktop:desktop /home/desktop/.xsession && \
    chmod +x /home/desktop/.xsession

# Configure XRDP to start XFCE
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec startxfce4\n' \
    > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    adduser xrdp ssl-cert

# Startup script
RUN cat > /usr/local/bin/start-desktop.sh <<'EOF'
#!/bin/bash
set -e

if [ -z "${RDP_PASSWORD:-}" ]; then
    echo "ERROR: Set the RDP_PASSWORD environment variable in Railway."
    exit 1
fi

RDP_USER="${RDP_USER:-desktop}"

if ! id "$RDP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$RDP_USER"
    echo "$RDP_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$RDP_USER"
    chmod 0440 "/etc/sudoers.d/$RDP_USER"
fi

echo "$RDP_USER:$RDP_PASSWORD" | chpasswd
echo "startxfce4" > "/home/$RDP_USER/.xsession"
chown "$RDP_USER:$RDP_USER" "/home/$RDP_USER/.xsession"

mkdir -p /var/run/dbus
dbus-daemon --system --fork || true

service xrdp-sesman start
service xrdp start

echo "XRDP started on port 3389"
tail -F /var/log/xrdp.log /var/log/xrdp-sesman.log
EOF

RUN chmod +x /usr/local/bin/start-desktop.sh

EXPOSE 3389
EXPOSE 5901
EXPOSE 6080

CMD ["/usr/local/bin/start-desktop.sh"]
