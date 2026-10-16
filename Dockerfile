FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# 1. Bật kiến trúc i386 để hỗ trợ Wine 32-bit
RUN dpkg --add-architecture i386

# 2. Cài đặt XFCE4, XRDP, Wine, Firefox và Audio
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    ssl-cert \
    tigervnc-standalone-server \
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    pulseaudio \
    pulseaudio-utils \
    wine \
    wine32 \
    wine64 \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# 3. Cấu hình âm thanh PulseAudio (thay thế cho file pulse-client.conf rời)
RUN mkdir -p /etc/pulse && \
    echo "default-server = unix:/run/pulse/native\nautospawn = no\ndaemon-binary = /bin/true" > /etc/pulse/client.conf

# 4. Cấu hình tài khoản root
RUN echo "root:root" | chpasswd && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# 5. Fix lỗi bấm ứng dụng không mở được trên XFCE bằng D-Bus session
RUN echo '#!/bin/sh' > /etc/xrdp/startwm.sh && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /etc/xrdp/startwm.sh && \
    echo 'unset XDG_RUNTIME_DIR' >> /etc/xrdp/startwm.sh && \
    echo 'exec dbus-launch --exit-with-session startxfce4' >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    cp /etc/xrdp/startwm.sh /root/.xsession && \
    chmod 700 /root/.xsession

# 6. Tối ưu XRDP chạy trên Docker qua cổng 3389
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

EXPOSE 3389

# 7. Khởi động dịch vụ (tự động dọn dẹp lock file và giữ tiến trình)
CMD bash -c "rm -rf /var/run/xrdp/* /var/run/dbus/* && mkdir -p /var/run/xrdp/sockdir /var/run/dbus && chown -R xrdp:xrdp /var/run/xrdp && dbus-daemon --system --fork; /usr/sbin/xrdp-sesman; exec /usr/sbin/xrdp -n"
