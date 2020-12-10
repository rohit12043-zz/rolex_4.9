#!/usr/bin/env bash

echo "Cloning dependencies"

git clone --depth=1 https://github.com/rohit12043/rolex_4.9 -b rework kernel
cd kernel
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git -b lineage-17.1 gcc-64 --depth=1
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git -b lineage-17.1 gcc-32 --depth=1
git clone --depth=1 https://github.com/rohit12043/AnyKernel3 AnyKernel

echo "Done"

IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
GCC_VERSION=$(gcc-64/bin/aarch64-linux-android-gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export CONFIG_PATH=$PWD/arch/arm64/configs/rolex_defconfig
PATH="${PWD}/gcc-64/bin:${PWD}/gcc-32/bin:$PATH"

export ARCH=arm64
export KBUILD_BUILD_HOST=DorimeKernel
export KBUILD_BUILD_USER="rohit12043"

# sticker plox

function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgEAAxkBAAIEJ1-663zC8M1L_kjXEeDnpR0vI4IHAAJFAQAC_sJVOEJ772_9dLo1HgQ" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• DorimeKernel •</b>%0ABuild started on <code>Circle CI/CD</code>%0A <b>For device</b> <i>Xiaomi Redmi 4A (rolex)</i>%0A<b>branch:-</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0A<b>Under commit</b> <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0A<b>Using compiler:- </b> <code>$GCC_VERSION</code>%0A<b>Started on:- </b> <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}
# Push kernel to channel

function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Xiaomi Redmi 4A (rolex)</b> | <b>$GCC_VERSION</b>"
}
# Fin Error

function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Compile plox

function compile() {
   make O=out ARCH=arm64 rolex_defconfig
       make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CROSS_COMPILE="$(pwd)/gcc-64/bin/aarch64-linux-android-" \
                      CROSS_COMPILE_ARM32="$(pwd)/gcc-32/bin/arm-linux-androideabi-"

if [ `ls "$IMAGE" 2>/dev/null | wc -l` != "0" ]
then
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
else
   finerr
fi
}
# Zipping

function zipping() {
    cd AnyKernel || exit 1
    zip -r9 DorimeKernel-rolex-${TANGGAL}.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
