#!/bin/bash
set -e  # 遇到错误立即退出
# old version kernel 5.16
# git clone https://github.com/ccmx200/linux.git -b op9-next-modem
# cd linux
# cp ../config-qcom-sm8350 config-qcom-sm8350
# make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc defconfig config-qcom-sm8350
# make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc 
# make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc bindeb-pkg

# new version kernel 6.7
wget -q https://gitlab.com/sm8350-mainline/linux/-/archive/ffb1b0db511df03829fa0c9682f2412c0db7f717.tar.gz 
tar zxvf ffb1b0db511df03829fa0c9682f2412c0db7f717.tar.gz
cd linux-ffb1b0db511df03829fa0c9682f2412c0db7f717/

make -j$(nproc) ARCH=arm64 sm8350.config
make -j$(nproc) ARCH=arm64  
make -j$(nproc) ARCH=arm64 bindeb-pkg

cd ..
# 清理源码目录
rm -rf linux

