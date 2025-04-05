#!/usr/sbin/zsh

ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

SRCDIR=$HOME/sources
MODULES_BUILD_PATH=$SRCDIR/rasplinux
RASP_URL=pi@raspberrypi.local

function install_modules () {
    local lunatik_root=$HOME/sources/lunatik
    pushd $lunatik_root
    make clean
    make  -j$(nproc) MODULES_BUILD_PATH=$MODULES_BUILD_PATH \
        ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} &&

    grep '\${INSTALL}' Makefile | \
        perl -pe 's/^\s*\$\{INSTALL\}\s+-m\s+\d+\s+(.+) [^\s]+$/$1/' |
        (perl -nle 'print for glob($_)' && echo "Makefile") |
        tar -czf lunatik.tar.gz --ignore-failed-read --files-from=-
    scp lunatik.tar.gz $RASP_URL:~/
    ssh $RASP_URL \
        'tar -xvf lunatik.tar.gz -C lunatik && cd lunatik && sudo make install'
    rm lunatik.tar.gz
    popd
}
