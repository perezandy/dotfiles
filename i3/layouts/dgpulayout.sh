#!/bin/sh
xrandr \
  --output DP-1.1 --mode 1920x1080 --pos 4800x0 --rotate normal \
  --output DP-1.3 --mode 1920x1080 --pos 2880x0 --rotate normal \
  --output DP-0 --primary --mode 2880x1800 --pos 0x0 --rotate normal
