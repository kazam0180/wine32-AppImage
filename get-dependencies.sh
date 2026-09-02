#!/bin/sh

set -eu

ARCH=$(uname -m)

#echo "Enabling multilib repo..."
#echo "---------------------------------------------------------------"
#sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
#sudo pacman -Syu --noconfirm

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm wine # lib32-glibc

if [ "$ARCH" = 'x86_64' ]; then
	sudo pacman -S --noconfirm mingw-w64-binutils
fi

echo "Done."
