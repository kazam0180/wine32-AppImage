#!/bin/sh

# Minimal 32-bit CLI-only Wine AppImage
# For running CLI apps like COD1 map compiler (coutils.exe)
# Uses Kron4ek 32-bit wine build (no WoW64 needed)

set -eu

ARCH=$(uname -m)
VERSION="11.16"
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/bcf6aa9582f676e1c93d0022319e6055cd1f2de2/Papirus/64x64/apps/wine.svg
export DESKTOP=/usr/share/applications/wine.desktop
export APPNAME=wine32-cli

# Disable all GUI-related deployments for CLI-only mode
export DEPLOY_SDL=0
export DEPLOY_PIPEWIRE=0
export DEPLOY_GSTREAMER=0
export DEPLOY_VULKAN=0
export DEPLOY_OPENGL=0

# Deploy from Kron4ek 32-bit wine build
mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine quick-sharun \
	/tmp/wine-x86/bin/wine         \
	/tmp/wine-x86/bin/wineserver   \
	/tmp/wine-x86/bin/wineboot     \
	/tmp/wine-x86/bin/regsvr32     \
	/tmp/wine-x86/lib/wine

# alright here the pain starts
ln -sr ./AppDir/lib/wine/i386-unix/*.so* ./AppDir/bin

# Patch wine binary with random interpreter
kek=.$(tr -dc 'A-Za-z0-9_=-' < /dev/urandom | head -c 10)
rm -f ./AppDir/lib/wine/i386-unix/wine
cp /tmp/wine-x86/lib/wine/i386-unix/wine ./AppDir/lib/wine/i386-unix/wine
patchelf --set-interpreter /tmp/"$kek" ./AppDir/lib/wine/i386-unix/wine
patchelf --add-needed anylinux.so ./AppDir/shared/lib/libc.so.6

# Also need 32-bit ld-linux for the 32-bit wine binary
cp /lib/ld-linux.so.2 ./AppDir/shared/lib/ld-linux.so.2

cat <<EOF > ./AppDir/bin/random-linker.src.hook
#!/bin/sh
cp -f "\$APPDIR"/shared/lib/ld-linux*.so* /tmp/"$kek"
EOF
chmod +x ./AppDir/bin/*.hook

echo 'LD_LIBRARY_PATH=${APPDIR}/lib:${APPDIR}/lib/wine/i386-unix' >> ./AppDir/.env

# Strip Windows DLLs
if [ "$ARCH" = 'x86_64' ]; then
	i686-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll 2>/dev/null || true
fi

# Remove GUI-related wine DLLs from i386-windows (keep core APIs)
echo "Removing GUI wine DLLs..."
# Direct3D/DirectX
rm -f ./AppDir/lib/wine/i386-windows/d2d1.dll
rm -f ./AppDir/lib/wine/i386-windows/d3d*
rm -f ./AppDir/lib/wine/i386-windows/dx*
# DDraw
rm -f ./AppDir/lib/wine/i386-windows/ddraw*
rm -f ./AppDir/lib/wine/i386-windows/dciman*
# DirectInput
rm -f ./AppDir/lib/wine/i386-windows/dinput*
# DirectSound
rm -f ./AppDir/lib/wine/i386-windows/dsound*
rm -f ./AppDir/lib/wine/i386-windows/dsdmo*
rm -f ./AppDir/lib/wine/i386-windows/dswave*
# DirectPlay
rm -f ./AppDir/lib/wine/i386-windows/dplay*
rm -f ./AppDir/lib/wine/i386-windows/dpn*
rm -f ./AppDir/lib/wine/i386-windows/dpvoice*
rm -f ./AppDir/lib/wine/i386-windows/dpwsockx*
# DirectMusic
rm -f ./AppDir/lib/wine/i386-windows/dmband*
rm -f ./AppDir/lib/wine/i386-windows/dmcompos*
rm -f ./AppDir/lib/wine/i386-windows/dmime*
rm -f ./AppDir/lib/wine/i386-windows/dmloader*
rm -f ./AppDir/lib/wine/i386-windows/dmscript*
rm -f ./AppDir/lib/wine/i386-windows/dmstyle*
rm -f ./AppDir/lib/wine/i386-windows/dmsynth*
rm -f ./AppDir/lib/wine/i386-windows/dmusic*
# DirectShow
rm -f ./AppDir/lib/wine/i386-windows/amstream*
rm -f ./AppDir/lib/wine/i386-windows/devenum*
rm -f ./AppDir/lib/wine/i386-windows/qasf*
rm -f ./AppDir/lib/wine/i386-windows/qcap*
rm -f ./AppDir/lib/wine/i386-windows/qedit*
rm -f ./AppDir/lib/wine/i386-windows/quartz*
# OpenGL/Vulkan (keep opengl32 + glu32 for q3map)
rm -f ./AppDir/lib/wine/i386-windows/*vulkan*
# Display drivers
rm -f ./AppDir/lib/wine/i386-windows/winemac.drv
rm -f ./AppDir/lib/wine/i386-windows/winevulkan.drv
rm -f ./AppDir/lib/wine/i386-windows/winex11.drv
rm -f ./AppDir/lib/wine/i386-windows/winewayland.drv
# Audio
rm -f ./AppDir/lib/wine/i386-windows/xaudio2_*
rm -f ./AppDir/lib/wine/i386-windows/x3daudio1_*
rm -f ./AppDir/lib/wine/i386-windows/xactengine*
rm -f ./AppDir/lib/wine/i386-windows/xapofx1_*
rm -f ./AppDir/lib/wine/i386-windows/msacm*
rm -f ./AppDir/lib/wine/i386-windows/midimap*
rm -f ./AppDir/lib/wine/i386-windows/mci*.dll
# Media Foundation
rm -f ./AppDir/lib/wine/i386-windows/mf*.dll
# Camera/Twain
rm -f ./AppDir/lib/wine/i386-windows/avicap32.dll
rm -f ./AppDir/lib/wine/i386-windows/twain*
# Windows Media
rm -f ./AppDir/lib/wine/i386-windows/wmadmod*
rm -f ./AppDir/lib/wine/i386-windows/wmasf*
rm -f ./AppDir/lib/wine/i386-windows/wmvcore*
rm -f ./AppDir/lib/wine/i386-windows/wmvdecod*
rm -f ./AppDir/lib/wine/i386-windows/wmp*
# Video/media/codec
rm -f ./AppDir/lib/wine/i386-windows/vidreszr.dll
rm -f ./AppDir/lib/wine/i386-windows/msvproc.dll
rm -f ./AppDir/lib/wine/i386-windows/iyuv_32.dll
# Browser/image codecs
rm -f ./AppDir/lib/wine/i386-windows/mshtml.dll
rm -f ./AppDir/lib/wine/i386-windows/windowscodecs.dll
# Other GUI
rm -f ./AppDir/lib/wine/i386-windows/ninput*
rm -f ./AppDir/lib/wine/i386-windows/directmanipulation*
rm -f ./AppDir/lib/wine/i386-windows/magnification*
rm -f ./AppDir/lib/wine/i386-windows/inkobj*
rm -f ./AppDir/lib/wine/i386-windows/graphicscapture*
rm -f ./AppDir/lib/wine/i386-windows/uianimation*
rm -f ./AppDir/lib/wine/i386-windows/uiautomationcore*
rm -f ./AppDir/lib/wine/i386-windows/uiribbon*
rm -f ./AppDir/lib/wine/i386-windows/dcomp*
rm -f ./AppDir/lib/wine/i386-windows/dwmapi*
rm -f ./AppDir/lib/wine/i386-windows/dataexchange*
rm -f ./AppDir/lib/wine/i386-windows/twinapi.appcore*
rm -f ./AppDir/lib/wine/i386-windows/dxdiagn*
rm -f ./AppDir/lib/wine/i386-windows/gdi*
rm -f ./AppDir/lib/wine/i386-windows/msimg*

# Remove GUI-related wine .so from i386-unix
echo "Removing GUI wine .so files..."
rm -f ./AppDir/lib/wine/i386-unix/winevulkan.so
rm -f ./AppDir/lib/wine/i386-unix/winex11.so
rm -f ./AppDir/lib/wine/i386-unix/winewayland.so
rm -f ./AppDir/lib/wine/i386-unix/winealsa.so
rm -f ./AppDir/lib/wine/i386-unix/winepulse.so
rm -f ./AppDir/lib/wine/i386-unix/wineps.so
rm -f ./AppDir/lib/wine/i386-unix/winegstreamer.so
rm -f ./AppDir/lib/wine/i386-unix/winedmo.so
rm -f ./AppDir/lib/wine/i386-unix/avicap32.so
rm -f ./AppDir/lib/wine/i386-unix/gphoto2.so
rm -f ./AppDir/lib/wine/i386-unix/opencl.so
rm -f ./AppDir/lib/wine/i386-unix/qcap.so
rm -f ./AppDir/lib/wine/i386-unix/sane.so
rm -f ./AppDir/lib/wine/i386-unix/wpcap.so

# Remove unnecessary libraries for CLI-only mode
echo "Removing unnecessary libraries..."
rm -rf ./AppDir/lib/alsa-lib
rm -rf ./AppDir/lib/pulseaudio
rm -f ./AppDir/lib/libasound*
rm -f ./AppDir/lib/libpulse*
rm -f ./AppDir/lib/libFLAC*
rm -f ./AppDir/lib/libogg*
rm -f ./AppDir/lib/libopus*
rm -f ./AppDir/lib/libvorbis*
rm -f ./AppDir/lib/libmp3lame*
rm -f ./AppDir/lib/libmpg123*
rm -f ./AppDir/lib/libsndfile*
rm -f ./AppDir/lib/libdrm*
rm -f ./AppDir/lib/libEGL*
rm -f ./AppDir/lib/libGL*
rm -f ./AppDir/lib/libgallium*
rm -f ./AppDir/lib/libLLVM*
rm -f ./AppDir/lib/libSPIRV*
rm -f ./AppDir/lib/libgbm*
rm -f ./AppDir/lib/libpciaccess*
rm -f ./AppDir/lib/libX11*
rm -f ./AppDir/lib/libxcb*
rm -f ./AppDir/lib/libXcursor*
rm -f ./AppDir/lib/libXext*
rm -f ./AppDir/lib/libXfixes*
rm -f ./AppDir/lib/libXi*
rm -f ./AppDir/lib/libXrandr*
rm -f ./AppDir/lib/libXrender*
rm -f ./AppDir/lib/libXxf86vm*
rm -f ./AppDir/lib/libxkb*
rm -f ./AppDir/lib/libwayland*
rm -f ./AppDir/lib/libasyncns*
rm -f ./AppDir/lib/libdbus*
rm -f ./AppDir/lib/libsystemd*
rm -f ./AppDir/lib/libudev*
rm -f ./AppDir/lib/libpcap*
rm -f ./AppDir/lib/libsensors*
rm -f ./AppDir/lib/libusb*
rm -f ./AppDir/lib/libgphoto2*
rm -f ./AppDir/lib/libnl-*
rm -f ./AppDir/lib/libnss_*

# Remove unnecessary share data
rm -rf ./AppDir/share/X11
rm -rf ./AppDir/share/alsa
rm -rf ./AppDir/share/drirc.d
rm -rf ./AppDir/share/libdrm
rm -rf ./AppDir/share/glib-2.0
rm -rf ./AppDir/share/glvnd

# Clean up broken symlinks
find ./AppDir/ -xtype l -delete 2>/dev/null || true

# Turn AppDir into AppImage
quick-sharun --make-appimage
