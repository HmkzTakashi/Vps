FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    ssl-cert \
    tigervnc-standalone-server \
    dbus-x11 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/.*pam_systemd.so/#&/' /etc/pam.d/common-session && \
    sed -i 's/\[Xorg\]/\[Xorg_disabled\]/' /etc/xrdp/xrdp.ini && \
    sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini && \
    echo "root:root" | chpasswd && \
    echo "startxfce4" > /root/.xsession && \
    adduser xrdp ssl-cert

EXPOSE 3389

CMD ["sh", "-c", "rm -rf /var/run/xrdp/* /var/run/dbus/* && mkdir -p /var/run/xrdp/sockdir /var/run/dbus && chown -R xrdp:xrdp /var/run/xrdp && dbus-daemon --system --fork; /usr/sbin/xrdp-sesman; exec /usr/sbin/xrdp -n"]
