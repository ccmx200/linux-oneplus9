#!/bin/bash
set -e  # 遇到错误立即退出

git clone https://github.com/ccmx200/linux.git -b op9-next-modem
cd linux
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc defconfig config-postmarketos-qcom-sm8350
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc 
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc bindeb-pkg
cd ..
# 清理源码目录
rm -rf linux

