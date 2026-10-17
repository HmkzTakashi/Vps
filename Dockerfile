FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Bật kiến trúc 32-bit cho Wine
RUN dpkg --add-architecture i386

# 1. Cài đặt môi trường gốc Debian, XFCE4, XRDP, Wine, Firefox
RUN apt-get update && apt-get install -y \
    xrdp \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xorg \
    dbus-x11 \
    ssl-cert \
    tigervnc-standalone-server \
    devilspie2 \
    locales \
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

# 2. BỎ TIẾNG VIỆT - SỬ DỤNG TIẾNG ANH CHUẨN GỐC
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. Đặt XFCE Terminal làm terminal mặc định
RUN update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# 4. TỰ ĐỘNG CÂN CHỈNH: CỬA SỔ RỘNG BẰNG NHAU + VỪA VẶN MÀN HÌNH (DÀNH CHO JCUNGBAN)
RUN mkdir -p /home/jcungban/.config/devilspie2 && \
    printf 'if (get_window_type() == "WINDOW_TYPE_NORMAL") then\n\
    local sw, sh = get_screen_geometry();\n\
    local x, y, w, h = get_window_geometry();\n\
    local target_w = sw - 18;\n\
    local target_x = 2;\n\
    local target_h = math.min(h, sh - 85);\n\
    local target_y = math.max(y, 28);\n\
    set_window_geometry(target_x, target_y, target_w, target_h);\n\
end\n' > /home/jcungban/.config/devilspie2/fit_screen.lua

# 5. TẠO TÀI KHOẢN jcungban : meows.vn VÀ CẤP QUYỀN SUDO
RUN useradd -m -s /bin/bash jcungban && \
    echo "jcungban:meows.vn" | chpasswd && \
    echo "jcungban ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jcungban && \
    mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id && \
    mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# 6. Cấu hình âm thanh pulse-client.conf
RUN mkdir -p /etc/pulse && \
    printf 'default-server = unix:/run/pulse/native\nautospawn = no\ndaemon-binary = /bin/true\n' > /etc/pulse/client.conf

# 7. Khởi động XFCE cùng D-Bus và script căn chỉnh cho jcungban
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexport LANG=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8\ndevilspie2 &\nexec dbus-launch --exit-with-session startxfce4\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    echo "startxfce4" > /home/jcungban/.xsession && chmod 700 /home/jcungban/.xsession

# 8. Cấu hình XRDP
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# 9. Chống trôi cửa sổ phía XFCE cho jcungban
RUN mkdir -p /home/jcungban/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfwm4" version="1.0">\n  <property name="general" type="empty">\n    <property name="prevent_placement_offscreen" type="bool" value="true"/>\n  </property>\n</channel>\n' > /home/jcungban/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# Cấp quyền sở hữu toàn bộ cấu hình cho user jcungban
RUN chown -R jcungban:jcungban /home/jcungban

# 10. File khởi động
RUN printf '#!/bin/bash\nrm -rf /var/run/xrdp/* /var/run/dbus/*\nmkdir -p /var/run/xrdp/sockdir /var/run/dbus\nchown -R xrdp:xrdp /var/run/xrdp\ndbus-daemon --system --fork\n/usr/sbin/xrdp-sesman\nexec /usr/sbin/xrdp -n\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
