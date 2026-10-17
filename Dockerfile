FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Bật kiến trúc 32-bit cho Wine
RUN dpkg --add-architecture i386

# 1. Cài đặt giao diện gốc, Xfce Terminal chuẩn, Wine, Firefox và BỘ FONT TIẾNG VIỆT
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xorg \
    dbus-x11 \
    ssl-cert \
    tigervnc-standalone-server \
    locales \
    fonts-dejavu \
    fonts-liberation \
    fonts-noto \
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

# 2. CẤU HÌNH TIẾNG VIỆT UTF-8 (Hết lỗi font ô vuông / dấu hỏi)
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# vi_VN.UTF-8 UTF-8/vi_VN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. ĐẶT XFCE TERMINAL LÀM MẶC ĐỊNH (Loại bỏ Zutty)
RUN update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# 4. CẤU HÌNH XFCE TERMINAL CHUẨN: ĐỌC TIẾNG VIỆT + KHÔNG TRÀN VIỀN
RUN mkdir -p /root/.config/xfce4/terminal && \
    printf '[Configuration]\nFontName=DejaVu Sans Mono 9\nMiscDefaultGeometry=64x22\nMiscMenubarDefault=TRUE\nMiscBordersDefault=TRUE\n' > /root/.config/xfce4/terminal/terminalrc

# 5. Cấu hình tài khoản root:root và X11
RUN echo "root:root" | chpasswd && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id && \
    mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# 6. Cấu hình âm thanh pulse-client.conf
RUN mkdir -p /etc/pulse && \
    printf 'default-server = unix:/run/pulse/native\nautospawn = no\ndaemon-binary = /bin/true\n' > /etc/pulse/client.conf

# 7. Khởi động XFCE có nạp biến môi trường UTF-8
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexport LANG=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8\nexec dbus-launch --exit-with-session startxfce4\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    echo "startxfce4" > /root/.xsession && chmod 700 /root/.xsession

# 8. Cấu hình XRDP
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

# 9. Tính năng gốc XFCE chống trôi cửa sổ ra mép
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfwm4" version="1.0">\n  <property name="general" type="empty">\n    <property name="prevent_placement_offscreen" type="bool" value="true"/>\n  </property>\n</channel>\n' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# 10. File start.sh
RUN printf '#!/bin/bash\nrm -rf /var/run/xrdp/* /var/run/dbus/*\nmkdir -p /var/run/xrdp/sockdir /var/run/dbus\nchown -R xrdp:xrdp /var/run/xrdp\ndbus-daemon --system --fork\n/usr/sbin/xrdp-sesman\nexec /usr/sbin/xrdp -n\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
