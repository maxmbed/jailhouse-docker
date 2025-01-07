#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # QEMU graphical window' ${TARGET_DIR}/etc/inittab
fi

topdir=/jailhouse-build/buildroot

# Install python depency for Jailhouse
python3 -m venv ${topdir}/../.jailhouse-venv
. ${topdir}/../.jailhouse-venv/bin/activate
pip3 install mako

# Build Jailhouse hypervisor, inmate and cell
export PATH=${topdir}/../materials/sdk/x86_64-jailhouse-linux-gnu_sdk-buildroot/bin:$PATH
cd ${topdir}/../jailhouse
make -j$(nproc) KDIR=${topdir}/output/build/linux-custom ARCH=x86_64 CROSS_COMPILE=x86_64-jailhouse-linux-gnu-

# Install to target directory
export prefix=${TARGET_DIR}/usr/local
export completionsdir=${TARGET_DIR}/usr/share/bash-completion/completions
export firmwaredir=${TARGET_DIR}/lib/firmware

make install KDIR=${topdir}/output/build/linux-custom DESTDIR=${TARGET_DIR} ARCH=x86_64 CROSS_COMPILE=x86_64-jailhouse-linux-gnu-

# Manually install cells and inmates
mkdir -p ${TARGET_DIR}/etc/jailhouse/configs ${TARGET_DIR}/etc/jailhouse/inmates
cp -r ${topdir}/../jailhouse/configs/x86/*.cell ${TARGET_DIR}/etc/jailhouse/configs
cp -r ${topdir}/../jailhouse/inmates/demos/x86/*.bin -t ${TARGET_DIR}/etc/jailhouse/inmates

# Leave python venv
deactivate
