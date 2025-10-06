#!/bin/sh
xrandr \
  --output HDMI-0 --off \
  --output DP-0 --off \
  --output DP-1 --off \
  --output DP-2 --off \
  --output DP-1-1 --off \
  --output DP-1-2 --off \
  --output DP-1-3 --off \
  --output DP-1-4 --off \
  --output DP-1-5 --off \
  --output DP-1-6 --off \
  --output DP-1-7 --off \
  --output DP-1-8 --off \
  --output eDP-1-1 --primary --mode 2880x1800 --pos 0x0 --rotate normal \
  --output DP-1-9 --off \
  --output DP-1-11 --off

sleep 1

xrandr \
  --output HDMI-0 --off \
  --output eDP-1-1 --primary --mode 2880x1800 --pos 0x0 --rotate normal \
  --output DP-1-9 --mode 1920x1080 --pos 4800x0 --rotate normal \
  --output DP-1-11 --mode 1920x1080 --pos 2880x0 --rotate normal
