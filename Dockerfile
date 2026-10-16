FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

RUN dpkg --add-architecture i386

# Cài đặt XFCE4, XRDP, Wine, Firefox và Audio
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    ssl-cert \
    tigervnc-standalone-server \
    x11-xserver-utils \
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

RUN mkdir -p /etc/pulse && \
    echo "default-server = unix:/run/pulse/native\nautospawn = no\ndaemon-binary = /bin/true" > /etc/pulse/client.conf

RUN echo "root:root" | chpasswd && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id

# CẤU HÌNH CỬA SỔ TERMINAL VỪA KHÍT MÀN HÌNH ĐIỆN THOẠI:
# Giảm chiều rộng xuống 48 cột để không bị tràn mất nút X ở mép phải
RUN mkdir -p /root/.config/xfce4/terminal && \
    printf '[Configuration]\nMiscDefaultGeometry=48x16\nFontName=Monospace 9\n' > /root/.config/xfce4/terminal/terminalrc

# Khởi chạy XFCE với D-Bus chuẩn
RUN echo '#!/bin/sh' > /etc/xrdp/startwm.sh && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /etc/xrdp/startwm.sh && \
    echo 'unset XDG_RUNTIME_DIR' >> /etc/xrdp/startwm.sh && \
    echo 'exec dbus-launch --exit-with-session startxfce4' >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    cp /etc/xrdp/startwm.sh /root/.xsession && \
    chmod 700 /root/.xsession

RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

EXPOSE 3389

CMD bash -c "rm -rf /var/run/xrdp/* /var/run/dbus/* && mkdir -p /var/run/xrdp/sockdir /var/run/dbus && chown -R xrdp:xrdp /var/run/xrdp && dbus-daemon --system --fork; /usr/sbin/xrdp-sesman; exec /usr/sbin/xrdp -n"
