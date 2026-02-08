#!/bin/bash
set -e

# 创建工作目录
mkdir -p rootdir

# 下载并安装 Debian Trixie 基础系统
echo "正在初始化 Debian Trixie 基础系统..."
debootstrap --arch=arm64 trixie rootdir http://deb.debian.org/debian/

# 配置网络
echo "nameserver 8.8.8.8" > rootdir/etc/resolv.conf
echo "nameserver 1.1.1.1" >> rootdir/etc/resolv.conf

# 挂载必要的文件系统
mount --bind /dev rootdir/dev
mount --bind /dev/pts rootdir/dev/pts
mount --bind /proc rootdir/proc
mount --bind /sys rootdir/sys

# 配置 apt 源
echo "deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware" > rootdir/etc/apt/sources.list
echo "deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware" >> rootdir/etc/apt/sources.list
echo "deb http://deb.debian.org/debian-security/ trixie-security main contrib non-free non-free-firmware" >> rootdir/etc/apt/sources.list

# 安装基本工具和依赖
echo "正在安装基本工具和依赖..."
chroot rootdir apt update
chroot rootdir apt install -y wget curl git sudo nano vim net-tools iputils-ping \
    network-manager openssh-server udev systemd-timesyncd \
    linux-base initramfs-tools \
    locales locales-all keyboard-configuration console-setup \
    wireless-tools wpasupplicant \
    bluez bluez-tools \
    alsa-utils pulseaudio \
    libinput10 libinput-tools \
    libwayland-server0 libwayland-client0 libwayland-cursor0 \
    libegl1-mesa libgles2-mesa libgbm1 \
    mesa-utils mesa-utils-extra \
    libgl1-mesa-dri libglx-mesa0 \
    libfontconfig1 libfreetype6 libxft2 \
    libx11-6 libx11-xcb1 libxcb1 libxcb-util0 libxcb-xkb1 \
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
    libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-shm0 \
    libxcb-sync1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 \
    libxkbcommon0 libxkbcommon-x11-0 \
    libpam-systemd libnss-systemd \
    systemd-sysv dbus dbus-user-session \
    policykit-1 policykit-1-gnome \
    libcanberra0 libcanberra-gtk3-0 libcanberra-gtk-module \
    gvfs gvfs-backends gvfs-fuse \
    at-spi2-core at-spi2-common \
    libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
    libcairo2 libcairo-gobject2 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 libglib2.0-bin \
    libgtk-3-0 libgtk-3-common \
    libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 \
    xdg-utils xdg-desktop-portal xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    libpipewire-0.3-0 libpipewire-0.3-modules libwireplumber-0.4-0 \
    pipewire pipewire-audio pipewire-jack pipewire-pulse \
    wireplumber \
    fontconfig fonts-dejavu-core fonts-freefont-ttf fonts-liberation \
    fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji \
    xfonts-base xfonts-75dpi xfonts-100dpi \
    hicolor-icon-theme adwaita-icon-theme \
    gnome-themes-standard gtk2-engines-pixbuf \
    libasound2 libasound2-plugins \
    libpulse0 pulseaudio-utils \
    libsndfile1 libsamplerate0 \
    sound-theme-freedesktop

# 安装中文语言支持
echo "正在安装中文语言支持..."
chroot rootdir apt install -y locales locales-all \
    language-pack-zh-hans language-pack-zh-hans-base \
    language-pack-zh-hant language-pack-zh-hant-base \
    fonts-noto-cjk fonts-noto-cjk-extra \
    fonts-wqy-zenhei fonts-wqy-microhei \
    xfonts-intl-chinese xfonts-wqy \
    libpinyin-data libpinyin15 ibus-libpinyin \
    ibus-table ibus-table-wubi \
    fcitx fcitx-googlepinyin fcitx-sunpinyin fcitx-pinyin \
    fcitx-rime fcitx-config-gtk \
    im-config

# 配置中文环境
echo "正在配置中文环境..."
chroot rootdir update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8

# 创建用户
echo "正在创建用户..."
chroot rootdir useradd -m -s /bin/bash -G sudo,adm,wheel,audio,video,plugdev,netdev,lp,cdrom user
chroot rootdir echo "user:user" | chpasswd
chroot rootdir echo "root:root" | chpasswd

# 配置 sudo
echo "正在配置 sudo..."
chroot rootdir echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user
chroot rootdir chmod 440 /etc/sudoers.d/user

# 配置主机名
echo "oneplus-lemonade" | tee rootdir/etc/hostname
echo "127.0.0.1 localhost" > rootdir/etc/hosts
echo "127.0.1.1 oneplus-lemonade" >> rootdir/etc/hosts

# 安装设备特定软件包
echo "正在安装设备特定软件包..."
chroot rootdir apt install -y rmtfs protection-domain-mapper tqftpserv

# 修改服务配置
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service

# 复制并安装内核包（从预下载的目录）
echo "正在安装内核包..."
cp oneplus-lemonade-debs/*.deb rootdir/tmp/
chroot rootdir dpkg -i /tmp/*.deb
rm rootdir/tmp/*.deb
chroot rootdir update-initramfs -c -k all

# # 配置 NCM
# cat > rootdir/etc/dnsmasq.d/usb-ncm.conf << 'EOF'
# interface=usb0
# bind-dynamic
# port=0
# dhcp-authoritative
# dhcp-range=172.16.42.2,172.16.42.254,255.255.255.0,1h
# dhcp-option=3,172.16.42.1
# dhcp-option=6,8.8.8.8,1.1.1.1
# EOF
# echo "net.ipv4.ip_forward=1" | tee rootdir/etc/sysctl.d/99-usb-ncm.conf
# chroot rootdir systemctl enable dnsmasq
# cat > rootdir/usr/local/sbin/setup-usb-ncm.sh << 'EOF'
# #!/bin/sh
# set -e

# modprobe libcomposite
# mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config

# G=/sys/kernel/config/usb_gadget/g1
# mkdir -p "$G"
# echo 0x1d6b > "$G/idVendor"
# echo 0x0104 > "$G/idProduct"
# echo 0x0100 > "$G/bcdDevice"
# echo 0x0200 > "$G/bcdUSB"
# mkdir -p "$G/strings/0x409"
# echo "oneplus-lemonade" > "$G/strings/0x409/serialnumber"
# echo "OnePlus" > "$G/strings/0x409/manufacturer"
# echo "OnePlus Lemonade" > "$G/strings/0x409/product"

# mkdir -p "$G/configs/c.1/strings/0x409"
# echo "Config 1: ECM network" > "$G/configs/c.1/strings/0x409/configuration"
# echo 500 > "$G/configs/c.1/MaxPower"

# mkdir -p "$G/functions/ecm.usb0"
# HOST="00:dc:c8:f7:75:14"
# DEV="00:dd:dc:eb:6d:a1"
# echo "$HOST" > "$G/functions/ecm.usb0/host_addr"
# echo "$DEV" > "$G/functions/ecm.usb0/dev_addr"
# ln -s "$G/functions/ecm.usb0" "$G/configs/c.1/"

# ls /sys/class/udc > "$G/UDC"

# ip link set usb0 up
# ip addr add 172.16.42.1/24 dev usb0
# EOF
# chmod +x rootdir/usr/local/sbin/setup-usb-ncm.sh

# # 配置启动脚本
# cat > rootdir/etc/systemd/system/usb-ncm.service << 'EOF'
# [Unit]
# Description=USB NCM Network Setup
# After=multi-user.target

# [Service]
# Type=oneshot
# ExecStart=/usr/local/sbin/setup-usb-ncm.sh

# [Install]
# WantedBy=multi-user.target
# EOF
# chroot rootdir systemctl enable usb-ncm

# 配置网络管理器
echo "正在配置网络管理器..."
chroot rootdir systemctl enable NetworkManager

# 配置 SSH
echo "正在配置 SSH..."
chroot rootdir systemctl enable ssh

# 配置自动登录
echo "正在配置自动登录..."
cat > rootdir/etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin user --noclear %I $TERM
EOF

# 配置屏幕控制
echo "正在配置屏幕控制..."
cat > rootdir/usr/local/bin/leijun << 'EOF'
#!/bin/bash
echo 0 > /sys/class/backlight/panel0-backlight/brightness
EOF
chmod +x rootdir/usr/local/bin/leijun

cat > rootdir/usr/local/bin/jinfan << 'EOF'
#!/bin/bash
echo 200 > /sys/class/backlight/panel0-backlight/brightness
EOF
chmod +x rootdir/usr/local/bin/jinfan

# 配置自动熄屏
echo "正在配置自动熄屏..."
cat > rootdir/etc/systemd/system/screen-off.service << 'EOF'
[Unit]
Description=Turn off screen after boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sleep 15 && /usr/local/bin/leijun

[Install]
WantedBy=multi-user.target
EOF
chroot rootdir systemctl enable screen-off

# 清理和卸载
echo "正在清理和卸载..."
chroot rootdir apt clean
umount rootdir/dev/pts
umount rootdir/dev
umount rootdir/proc
umount rootdir/sys

# 压缩镜像
echo "正在压缩镜像..."
7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on rootfs.7z rootdir

echo "构建完成! 系统镜像已保存为 rootfs.7z"
echo "使用方法: 解压后通过 fastboot 刷入 userdata 分区"
echo "fastboot flash userdata rootfs.img"
