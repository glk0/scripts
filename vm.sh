#!/usr/sbin/zsh

SRCDIR=$HOME/sources
VMDIR=$SRCDIR/vm
VMDISK=$VMDIR/disks/disk.img
KDIR=$SRCDIR/linux
BZIMAGE=$VMDIR/kernels/bzImage
MOUNTPOINT=$VMDIR/mnt

function vmup() {
    qemu-system-x86_64 -kernel $BZIMAGE \
        -drive file=$VMDIR/disks/disk.img,format=raw \
        -append "console=ttyS0 root=/dev/sda rw quiet" \
        -m 2048 -smp 2 -cpu SandyBridge \
        -serial mon:stdio\
        -nographic -D $VMDIR/logs/qemu.log \
}
function mnt() {
    mkdir $MOUNTPOINT
    sudo mount -o loop $VMDISK $MOUNTPOINT
}

function umnt(){
    sudo umount $MOUNTPOINT || true
    rm  -d $MOUNTPOINT || true
}

function install_modules () {
    sudo -v
    local kernel_release=$(file "$BZIMAGE" | sed -n 's/.*version \(.*\) (.*/\1/p')
    if [ -z $kernel_release ]; then
        echo "unable to extract correct kernel version"
        return 1
    fi
    local modules_install_path=$MOUNTPOINT/lib/modules/${kernel_release}
    local scripts_install_path=$MOUNTPOINT/lib/modules/lua
    local lunatik_install_path=$MOUNTPOINT/usr/sbin
    local lunatik_ebpf_install_path=$MOUNTPOINT/usr/lib/bpf/lunatik
    local lunatik_root=$HOME/sources/lunatik

    pushd $lunatik_root
    mnt &&
    make  -j$(nproc) KDIR=$KDIR LLVM=1 &&
    sudo make -j$(nproc) install KDIR=$KDIR KERNEL_RELEASE=$kernel_release LLVM=1 \
        LUNATIK_INSTALL_PATH=$lunatik_install_path \
        SCRIPTS_INSTALL_PATH=$scripts_install_path \
        MODULES_INSTALL_PATH=$modules_install_path \
        LUNATIK_EBPF_INSTALL_PATH=$lunatik_ebpf_install_path
    sudo make -j$(nproc) examples_install KDIR=$KDIR KERNEL_RELEASE=$kernel_release LLVM=1 \
        LUNATIK_INSTALL_PATH=$lunatik_install_path \
        SCRIPTS_INSTALL_PATH=$scripts_install_path \
        MODULES_INSTALL_PATH=$modules_install_path \
        LUNATIK_EBPF_INSTALL_PATH=$lunatik_ebpf_install_path
    umnt
    popd
}

function e_init_script () {
    mnt
    vim $MOUNTPOINT/etc/init.d/rcS
    umnt
}
