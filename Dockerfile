FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    xrdp xorgxrdp \
    dbus-x11 \
    sudo curl wget \
    ca-certificates \
    net-tools \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# Fix lỗi bảo mật và cấp quyền cho xrdp
RUN adduser xrdp ssl-cert && \
    sed -i 's/3389/3389/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/crypt_level=high/crypt_level=low/g' /etc/xrdp/xrdp.ini

# Tạo script khởi động tối ưu cho XRDP
RUN cat > /usr/local/bin/start-desktop.sh <<'EOF'
#!/bin/bash
set -e

RDP_USER="${RDP_USER:-desktop}"
RDP_PASSWORD="${RDP_PASSWORD:-123456}"

# Tạo user nếu chưa tồn tại
if ! id "$RDP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$RDP_USER"
    echo "$RDP_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$RDP_USER"
    chmod 0440 "/etc/sudoers.d/$RDP_USER"
fi

# Đặt mật khẩu (mặc định là 123456 nếu không đặt RDP_PASSWORD trên Railway)
echo "$RDP_USER:$RDP_PASSWORD" | chpasswd

# Cấu hình session XFCE chống màn hình đen
echo "unset DBUS_SESSION_BUS_ADDRESS" > "/home/$RDP_USER/.xsession"
echo "unset XDG_RUNTIME_DIR" >> "/home/$RDP_USER/.xsession"
echo "exec startxfce4" >> "/home/$RDP_USER/.xsession"
chown "$RDP_USER:$RDP_USER" "/home/$RDP_USER/.xsession"
chmod +x "/home/$RDP_USER/.xsession"

# Dọn dẹp PID cũ nếu container restart
rm -rf /var/run/xrdp/* /var/run/dbus/*
mkdir -p /var/run/dbus
dbus-daemon --system --fork || true

# Khởi động dịch vụ
service xrdp-sesman start
service xrdp start

echo "=========================================="
echo "XRDP is listening on port 3389"
echo "Username: $RDP_USER"
echo "Password: $RDP_PASSWORD"
echo "=========================================="

tail -f /var/log/xrdp.log /var/log/xrdp-sesman.log
EOF

RUN chmod +x /usr/local/bin/start-desktop.sh

EXPOSE 3389

CMD ["/usr/local/bin/start-desktop.sh"]