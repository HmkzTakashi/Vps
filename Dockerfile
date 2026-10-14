FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Cài đặt kiến trúc 32-bit cho Wine
RUN dpkg --add-architecture i386

# Cài đặt đầy đủ: xorgxrdp, ssl-cert, dbus và các công cụ cần thiết
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xfce4 \
    xfce4-goodies \
    xorg \
    dbus-x11 \
    ssl-cert \
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    pulseaudio \
    pulseaudio-utils \
    wine \
    wine32 \
    firefox-esr \
    ca-certificates \
    tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Cấu hình quyền cho Xorg & XRDP
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config
RUN adduser xrdp ssl-cert

# Giảm mã hóa RDP để tương thích mọi phần mềm Remote Desktop
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini

# Cấu hình khởi động giao diện XFCE chuẩn (chống lỗi màn hình đen)
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec startxfce4\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Tạo file chạy khởi động trực tiếp bên trong Docker (không cần COPY file ngoài)
RUN cat <<'EOF' > /start.sh
#!/bin/bash
set -e

# Đặt mật khẩu: Lấy từ biến môi trường RDP_PASSWORD, nếu không có thì mặc định là root
PASSWORD="${RDP_PASSWORD:-root}"
echo "root:$PASSWORD" | chpasswd

# Tạo thư mục và sinh machine-id cho dbus
mkdir -p /var/run/dbus /run/xrdp
dbus-uuidgen > /var/lib/dbus/machine-id 2>/dev/null || true
dbus-daemon --system --fork 2>/dev/null || true

# Khởi động dịch vụ sesman
xrdp-sesman

# Tạo trước file log nếu chưa có
touch /var/log/xrdp.log /var/log/xrdp-sesman.log

echo "XRDP đang chạy trên cổng 3389..."

# Chạy xrdp ở chế độ foreground (nodaemon) để giữ container luôn ACTIVE
exec xrdp -n
EOF

RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]