FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Cài đặt XFCE4 và XRDP
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    xrdp \
    tigervnc-standalone-server \
    dbus-x11 sudo \
    && rm -rf /var/lib/apt/lists/*

# Fix lỗi PAM (ngăn chặn tình trạng văng session khi đăng nhập)
RUN sed -i 's/.*pam_systemd.so/#&/' /etc/pam.d/common-session

# Chuyển XRDP sang chế độ Xvnc để không bị crash đồ họa trong Docker
RUN sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini

# Tạo tài khoản đăng nhập
RUN useradd -m -s /bin/bash desktop && \
    echo "desktop:123456" | chpasswd && \
    echo "desktop ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/desktop && \
    chmod 0440 /etc/sudoers.d/desktop && \
    echo "exec startxfce4" > /home/desktop/.xsession && \
    chown desktop:desktop /home/desktop/.xsession

RUN adduser xrdp ssl-cert

# Script khởi động trực tiếp cổng 3389
RUN echo '#!/bin/bash\n\
rm -rf /var/run/xrdp/*\n\
mkdir -p /var/run/xrdp /var/run/dbus /var/run/xrdp/sockdir\n\
chmod 2775 /var/run/xrdp\n\
chmod 3777 /var/run/xrdp/sockdir\n\
dbus-daemon --system --fork || true\n\
/usr/sbin/xrdp-sesman --nodaemon &\n\
exec /usr/sbin/xrdp --nodaemon\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]on"

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