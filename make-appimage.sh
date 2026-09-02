#!/bin/sh

# Minimal 32-bit CLI-only Wine AppImage
# For running CLI apps like COD1 map compiler (coutils.exe)
# Uses Wine WoW64 - 64-bit wine binary runs 32-bit Windows apps

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wine | awk '{print $2; exit}')
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

# Deploy only essential wine binaries and libs
mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine quick-sharun \
	/usr/bin/wine              \
	/usr/bin/wineserver        \
	/usr/bin/wineboot          \
	/usr/bin/regsvr32          \
	/usr/lib/wine

# alright here the pain starts
ln -sr ./AppDir/lib/wine/x86_64-unix/*.so* ./AppDir/bin

# this gets broken by sharun somehow
kek=.$(tr -dc 'A-Za-z0-9_=-' < /dev/urandom | head -c 10)
rm -f ./AppDir/lib/wine/x86_64-unix/wine
cp /usr/lib/wine/x86_64-unix/wine ./AppDir/lib/wine/x86_64-unix/wine
patchelf --set-interpreter /tmp/"$kek" ./AppDir/lib/wine/x86_64-unix/wine
patchelf --add-needed anylinux.so ./AppDir/shared/lib/libc.so.6

cat <<EOF > ./AppDir/bin/random-linker.src.hook
#!/bin/sh
cp -f "\$APPDIR"/shared/lib/ld-linux*.so* /tmp/"$kek"
EOF
chmod +x ./AppDir/bin/*.hook

echo 'LD_LIBRARY_PATH=${APPDIR}/lib:${APPDIR}/lib/wine/x86_64-unix' >> ./AppDir/.env

# Strip Windows DLLs
if [ "$ARCH" = 'x86_64' ]; then
	i686-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll 2>/dev/null || true
fi

# Remove x86_64 Windows DLLs - only need i386 for 32-bit apps
rm -rf ./AppDir/lib/wine/x86_64-windows

# Remove GUI-related wine DLLs from i386-windows
echo "Removing GUI wine DLLs..."
# Direct3D/DirectX
rm -f ./AppDir/lib/wine/i386-windows/d2d1.dll
rm -f ./AppDir/lib/wine/i386-windows/d3d*.dll
rm -f ./AppDir/lib/wine/i386-windows/d3dcompiler_*.dll
rm -f ./AppDir/lib/wine/i386-windows/d3dim*.dll
rm -f ./AppDir/lib/wine/i386-windows/d3drm.dll
rm -f ./AppDir/lib/wine/i386-windows/d3dx*.dll
rm -f ./AppDir/lib/wine/i386-windows/d3dxof.dll
rm -f ./AppDir/lib/wine/i386-windows/dx8vb.dll
rm -f ./AppDir/lib/wine/i386-windows/dxcore.dll
rm -f ./AppDir/lib/wine/i386-windows/dxdiagn.dll
rm -f ./AppDir/lib/wine/i386-windows/dxgi.dll
rm -f ./AppDir/lib/wine/i386-windows/dxtrans.dll
rm -f ./AppDir/lib/wine/i386-windows/dxva2.dll
# DDraw
rm -f ./AppDir/lib/wine/i386-windows/ddraw*.dll
rm -f ./AppDir/lib/wine/i386-windows/dciman32.dll
# DirectInput
rm -f ./AppDir/lib/wine/i386-windows/dinput*.dll
# DirectSound
rm -f ./AppDir/lib/wine/i386-windows/dsound.dll
rm -f ./AppDir/lib/wine/i386-windows/dsdmo.dll
rm -f ./AppDir/lib/wine/i386-windows/dswave.dll
# DirectPlay
rm -f ./AppDir/lib/wine/i386-windows/dplay*.dll
rm -f ./AppDir/lib/wine/i386-windows/dpn*.dll
rm -f ./AppDir/lib/wine/i386-windows/dpvoice.dll
rm -f ./AppDir/lib/wine/i386-windows/dpwsockx.dll
# DirectMusic
rm -f ./AppDir/lib/wine/i386-windows/dmband.dll
rm -f ./AppDir/lib/wine/i386-windows/dmcompos.dll
rm -f ./AppDir/lib/wine/i386-windows/dmime.dll
rm -f ./AppDir/lib/wine/i386-windows/dmloader.dll
rm -f ./AppDir/lib/wine/i386-windows/dmscript.dll
rm -f ./AppDir/lib/wine/i386-windows/dmstyle.dll
rm -f ./AppDir/lib/wine/i386-windows/dmsynth.dll
rm -f ./AppDir/lib/wine/i386-windows/dmusic*.dll
# DirectShow
rm -f ./AppDir/lib/wine/i386-windows/amstream.dll
rm -f ./AppDir/lib/wine/i386-windows/devenum.dll
rm -f ./AppDir/lib/wine/i386-windows/qasf.dll
rm -f ./AppDir/lib/wine/i386-windows/qcap.dll
rm -f ./AppDir/lib/wine/i386-windows/qedit.dll
rm -f ./AppDir/lib/wine/i386-windows/quartz.dll
# GDI/Graphics
rm -f ./AppDir/lib/wine/i386-windows/gdi32.dll
rm -f ./AppDir/lib/wine/i386-windows/gdiplus.dll
rm -f ./AppDir/lib/wine/i386-windows/glu32.dll
rm -f ./AppDir/lib/wine/i386-windows/opengl*.dll
rm -f ./AppDir/lib/wine/i386-windows/msimg32.dll
# Display drivers
rm -f ./AppDir/lib/wine/i386-windows/winemac.drv
rm -f ./AppDir/lib/wine/i386-windows/winevulkan.drv
rm -f ./AppDir/lib/wine/i386-windows/winex11.drv
rm -f ./AppDir/lib/wine/i386-windows/winewayland.drv
# Vulkan
rm -f ./AppDir/lib/wine/i386-windows/vulkan-1.dll
rm -f ./AppDir/lib/wine/i386-windows/winevulkan.dll
# Audio
rm -f ./AppDir/lib/wine/i386-windows/dsound.dll
rm -f ./AppDir/lib/wine/i386-windows/xaudio2_*.dll
rm -f ./AppDir/lib/wine/i386-windows/x3daudio1_*.dll
rm -f ./AppDir/lib/wine/i386-windows/xactengine*.dll
rm -f ./AppDir/lib/wine/i386-windows/xapofx1_*.dll
rm -f ./AppDir/lib/wine/i386-windows/msacm*.dll
rm -f ./AppDir/lib/wine/i386-windows/midimap.dll
rm -f ./AppDir/lib/wine/i386-windows/mci*.dll
# Media Foundation
rm -f ./AppDir/lib/wine/i386-windows/mf*.dll
# Camera/Twain
rm -f ./AppDir/lib/wine/i386-windows/avicap32.dll
rm -f ./AppDir/lib/wine/i386-windows/twain*.dll
# Other GUI
rm -f ./AppDir/lib/wine/i386-windows/ninput.dll
rm -f ./AppDir/lib/wine/i386-windows/directmanipulation.dll
rm -f ./AppDir/lib/wine/i386-windows/magnification.dll
rm -f ./AppDir/lib/wine/i386-windows/inkobj.dll
rm -f ./AppDir/lib/wine/i386-windows/graphicscapture.dll
rm -f ./AppDir/lib/wine/i386-windows/uianimation.dll
rm -f ./AppDir/lib/wine/i386-windows/uiautomationcore.dll
rm -f ./AppDir/lib/wine/i386-windows/uiribbon.dll
rm -f ./AppDir/lib/wine/i386-windows/dcomp.dll
rm -f ./AppDir/lib/wine/i386-windows/dwmapi.dll
rm -f ./AppDir/lib/wine/i386-windows/dataexchange.dll
rm -f ./AppDir/lib/wine/i386-windows/twinapi.appcore.dll
rm -f ./AppDir/lib/wine/i386-windows/d3dcompiler_*.dll

# Remove GUI-related wine .so from x86_64-unix
echo "Removing GUI wine .so files..."
rm -f ./AppDir/lib/wine/x86_64-unix/opengl32.so
rm -f ./AppDir/lib/wine/x86_64-unix/winevulkan.so
rm -f ./AppDir/lib/wine/x86_64-unix/wined3d.so
rm -f ./AppDir/lib/wine/x86_64-unix/winegstreamer.so
rm -f ./AppDir/lib/wine/x86_64-unix/winealsa.so
rm -f ./AppDir/lib/wine/x86_64-unix/winepulse.so
rm -f ./AppDir/lib/wine/x86_64-unix/wineps.so
rm -f ./AppDir/lib/wine/x86_64-unix/winex11.so
rm -f ./AppDir/lib/wine/x86_64-unix/winewayland.so
rm -f ./AppDir/lib/wine/x86_64-unix/avicap32.so
rm -f ./AppDir/lib/wine/x86_64-unix/gphoto2.so
rm -f ./AppDir/lib/wine/x86_64-unix/opencl.so
rm -f ./AppDir/lib/wine/x86_64-unix/winedmo.so
rm -f ./AppDir/lib/wine/x86_64-unix/qcap.so
rm -f ./AppDir/lib/wine/x86_64-unix/sane.so
rm -f ./AppDir/lib/wine/x86_64-unix/wpcap.so

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

# Clean up broken symlinks
find ./AppDir/ -xtype l -delete 2>/dev/null || true

# Turn AppDir into AppImage
quick-sharun --make-appimage
