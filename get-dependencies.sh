#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Enabling the multilib repo (needed for the lib32-* packages)..."
echo "---------------------------------------------------------------"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
	sh -c "printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf"
fi

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm cabextract lib32-pipewire-jack lib32-libpipewire lib32-pipewire lib32-zlib lib32-harfbuzz 7zip unzip fontconfig desktop-file-utils  	lib32-fontconfig libxkbcommon libxcursor lib32-libxkbcommon lib32-libxi lib32-libxrandr lib32-wayland lib32-libunwind

echo "installing wine32 from AUR"
#make-aur-package lib32-gettext
make-aur-package wine32 # lib32-gstreamer zenity-rs-bin lib32-ffmpeg

# Only install mingw strip tools for32-bit DLL stripping
if [ "$ARCH" = 'x86_64' ]; then
	# lib32-gcc-libs provides the 32-bit libgcc_s.so.1 needed to link
	# anylinux.so with -m32 (32-bit deployment mode of quick-sharun)
	pacman -S --noconfirm mingw-w64-binutils mingw-w64-gcc lib32-glibc lib32-gcc-libs
fi

echo "Done."
