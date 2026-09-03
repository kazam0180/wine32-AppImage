#!/bin/sh

set -eu

echo "Installing wine and dependencies..."
echo "---------------------------------------------------------------"
xbps-install -Syu wine winetricks gstreamer1 gst-libav ffmpeg gst-plugins-base1 gst-plugins-bad1 gst-plugins-ugly1 gst-plugins-good1 cabextract 7zip unzip libjack-pipewire pipewire alsa-pipewire SDL2

echo "Done."
