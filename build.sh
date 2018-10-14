#!/bin/sh

set -e

umask 0022
unset GREP_OPTIONS SED

git submodule update --remote

BUILD_DIST="sdCPE"
BUILD_HOST="downloads.tfury.com"
BUILD_TARGET=${BUILD_TARGET:-x86_64}
BUILD_REPO="http://${BUILD_HOST}/stable/${BUILD_TARGET}"

BUILD_MODULES=${BUILD_MODULES:-net-full nice-bb usb-full legacy}
BUILD_PACKAGES=${BUILD_PACKAGES:-vim-full netcat htop iputils-ping bmon bwm-ng screen mtr ss strace tcpdump-mini ethtool sysstat pciutils mini_snmpd dmesg}

for i in $BUILD_TARGET $BUILD_MODULES; do
	if [ ! -f "config/$i" ]; then
		echo "Config $i not found !"
		exit 1
	fi
done

cat > source/.config <<EOF
$(for i in $BUILD_TARGET $BUILD_MODULES; do cat "config/$i"; done)
CONFIG_GRUB_TITLE="$BUILD_DIST"
CONFIG_IMAGEOPT=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_DIST="$BUILD_DIST"
CONFIG_VERSION_REPO="$BUILD_REPO"
CONFIG_VERSION_NUMBER="$(git describe --tag --always)"
EOF

cd source
scripts/feeds clean
scripts/feeds update -a
scripts/feeds install -a -d y -f -p sdcpe
scripts/feeds install -a

cat >> .config << EOF
CONFIG_VERSION_CODE="$(git -C "feeds/sdcpe" describe --tag --always)"
$(for i in $BUILD_DIST $BUILD_PACKAGES; do echo "CONFIG_PACKAGE_$i=y"; done)
EOF

make defconfig
make "$@"
