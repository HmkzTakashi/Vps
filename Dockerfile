FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Bật kiến trúc 32-bit cho Wine
RUN dpkg --add-architecture i386

# Cài đặt đầy đủ các gói từ bản gốc debianxrdp
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
    wine64 \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Cấu hình âm thanh từ file pulse-client.conf gốc
RUN mkdir -p /etc/pulse && \
    printf 'default-server = unix:/run/pulse/native\nautospawn = no\ndaemon-binary = /bin/true\n' > /etc/pulse/client.conf

# Cài đặt mật khẩu root và sinh machine-id
RUN echo "root:root" | chpasswd && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id && \
    mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# CẤU HÌNH GỐC XFCE: CHỐNG TRÀN VIỀN, CĂN LỀ 12PX VÀ TỰ CĂN GIỮA MÀN HÌNH
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<channel name="xfwm4" version="1.0">\n\
  <property name="general" type="empty">\n\
    <property name="prevent_placement_offscreen" type="bool" value="true"/>\n\
    <property name="placement_mode" type="string" value="center"/>\n\
    <property name="snap_to_border" type="bool" value="true"/>\n\
    <property name="margin_left" type="int" value="12"/>\n\
    <property name="margin_right" type="int" value="12"/>\n\
  </property>\n\
</channel>\n' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# Cấu hình khởi động XFCE qua D-Bus
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec dbus-launch --exit-with-session startxfce4\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    cp /etc/xrdp/startwm.sh /root/.xsession && \
    chmod 700 /root/.xsession

# Cấu hình XRDP tương thích Windows RDP
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

# Tích hợp start.sh trực tiếp
RUN printf '#!/bin/bash\nrm -rf /var/run/xrdp/* /var/run/dbus/*\nmkdir -p /var/run/xrdp/sockdir /var/run/dbus\nchown -R xrdp:xrdp /var/run/xrdp\ndbus-daemon --system --fork\n/usr/sbin/xrdp-sesman\nexec /usr/sbin/xrdp -n\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
