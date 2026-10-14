# Khởi động XRDP
service xrdp-sesman start
service xrdp start

# Mở tự động TCP Tunnel không cần bấm gì trên Dashboard Railway:
echo "Đang tạo đường link Remote Desktop..."
ssh -o StrictHostKeyChecking=no -p 443 -R0:localhost:3389 a.pinggy.io tcp