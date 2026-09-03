#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Enabling the multilib repo (needed for the lib32-* packages)..."
echo "---------------------------------------------------------------"
if ! sudo grep -q '^\[multilib\]' /etc/pacman.conf; then
	sudo sh -c "printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf"
fi

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
sudo pacman -Syu --noconfirm cabextract lib32-pipewire-jack lib32-libpipewire lib32-pipewire lib32-zlib lib32-harfbuzz 7zip unzip fontconfig desktop-file-utils	lib32-fontconfig libxkbcommon lib32-libxcursor lib32-libxkbcommon lib32-libxi lib32-libxrandr lib32-wayland lib32-libunwind lib32-glib2	lib32-cairo  	lib32-pango	lib32-libogg lib32-libvorbis lib32-libxdamage lib32-libjpeg-turbo lib32-gtk3

# Only install mingw strip tools for32-bit DLL stripping
if [ "$ARCH" = 'x86_64' ]; then
	# lib32-gcc-libs provides the 32-bit libgcc_s.so.1 needed to link
	# anylinux.so with -m32 (32-bit deployment mode of quick-sharun)
	sudo pacman -S --noconfirm mingw-w64-binutils mingw-w64-gcc lib32-glibc lib32-gcc-libs
fi

# Download Kron4ek 32-bit wine build
TAG="$(curl -s https://api.github.com/repos/Kron4ek/Wine-Builds/releases/latest | jq -r '.tag_name')"
echo "Downloading Kron4ek wine $TAG x86..."
wget --retry-connrefused --tries=30 https://github.com/Kron4ek/Wine-Builds/releases/download/$TAG/wine-$TAG-x86.tar.xz -O /tmp/wine-x86.tar.xz
mkdir -p /tmp/wine-x86
tar -xf /tmp/wine-x86.tar.xz -C /tmp/wine-x86 --strip-components=1
sudo cp -r /tmp/wine-x86/* /usr/
rm -rf /tmp/wine*

make-aur-package lib32-libcaca lib32-faac lib32-orc lib32-v4l-utils lib32-libtheora lib32-libvpx  lib32-mpg123 lib32-libcap lib32-libsoup3 lib32-twolame lib32-ffmpeg

echo "Done."
