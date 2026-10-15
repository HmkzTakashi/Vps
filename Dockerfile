
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Cài đặt giao diện và XRDP
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    ssl-cert \
    tigervnc-standalone-server \
    dbus-x11 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Fix lỗi xác thực và chuyển sang chế độ ảo tránh văng màn hình trên Docker
RUN sed -i 's/.*pam_systemd.so/#&/' /etc/pam.d/common-session
RUN sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini

# Mở quyền cho phép đăng nhập tài khoản root trên XRDP
RUN sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini

# Đặt mật khẩu cho root và tạo phiên làm việc XFCE4
RUN echo "root:root" | chpasswd
RUN echo "startxfce4" > /root/.xsession

RUN adduser xrdp ssl-cert

EXPOSE 3389

# Lệnh chạy dịch vụ
CMD bash -c "rm -rf /var/run/xrdp/* /var/run/dbus/* && mkdir -p /var/run/xrdp/sockdir /var/run/dbus && chown -R xrdp:xrdp /var/run/xrdp && dbus-daemon --system --fork; /usr/sbin/xrdp-sesman; exec /usr/sbin/xrdp -n"us /var/run/xrdp/sockdir\n\
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