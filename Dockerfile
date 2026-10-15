FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Bật kiến trúc 32-bit để chạy Wine
RUN dpkg --add-architecture i386

# Cài đặt đầy đủ các gói của debianxrdp: XFCE, XRDP, Wine, Firefox, Audio
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    xorg \
    dbus-x11 \
    ssl-cert \
    tigervnc-standalone-server \
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    policykit-1 \
    pulseaudio \
    pulseaudio-utils \
    wine \
    wine32 \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Cấu hình tài khoản root
RUN echo "root:root" | chpasswd

# Cấu hình X11
RUN mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# SỬA TRIỆT ĐỂ LỖI BẤM ỨNG DỤNG KHÔNG MỞ:
# Khởi tạo dbus-launch --exit-with-session và xóa các biến xung đột
RUN echo '#!/bin/sh' > /etc/xrdp/startwm.sh && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /etc/xrdp/startwm.sh && \
    echo 'unset XDG_RUNTIME_DIR' >> /etc/xrdp/startwm.sh && \
    echo 'exec dbus-launch --exit-with-session startxfce4' >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    cp /etc/xrdp/startwm.sh /root/.xsession && \
    chmod 700 /root/.xsession

# Cấu hình XRDP tương thích Windows và cho phép root đăng nhập
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

EXPOSE 3389

# Khởi động dịch vụ XRDP
CMD bash -c "rm -rf /var/run/xrdp/* /var/run/dbus/* && mkdir -p /var/run/xrdp/sockdir /var/run/dbus && chown -R xrdp:xrdp /var/run/xrdp && dbus-daemon --system --fork; /usr/sbin/xrdp-sesman; exec /usr/sbin/xrdp -n"
