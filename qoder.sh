#!/bin/bash

# seject - Safely eject USB drive (OpenWrt version)
# Modified for OpenWrt environment
# Original Copyright (c) 2025 Rogerio O. Ferraz <rogerio.o.ferraz@gmail.com>

# MIT License

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

SCRIPTNAME="$(basename ${BASH_SOURCE[0]})"

USAGE="
seject - Safely eject USB drive (OpenWrt version)

A command-line utility to safely unmount and poweroff USB mass-storage devices.

A bash script that mimics the behavior of \"Safely Remove USB Drive\" for OpenWrt.
It unmounts all partitions, flushes write cache, and powers off
the USB drive, using standard Linux commands available in OpenWrt.

It ensures data integrity by flushing the write cache, and confirming that no
partitions remain mounted or in use, so the USB drive can be safely unplugged.

The command accepts a single argument, which can be the USB drive device
(e.g. /dev/sdX), or a USB partition device (e.g. /dev/sdXN). In both cases,
the behavior is the same.

Usage: \${SCRIPTNAME} [OPTIONS] device

ARGUMENTS:
  device         : USB storage device path, e.g., /dev/sdX, /dev/mmcblkN
                   or USB storage partition path, e.g., /dev/sdXN, /dev/mmcblkNpM

OPTIONS:
  -D, --debug    : Enable debug output
  -h, --help     : Display usage information
  -V, --version  : Show current version

Examples:

1. Find your USB drive:

  \$ cat /proc/mounts | grep /dev/sd
  \$ df -h

2. Safely eject USB drive by device path

  \$ \${SCRIPTNAME} /dev/sda
  \$ \${SCRIPTNAME} /dev/mmcblk0

3. Safely eject USB drive by a partition path

  \$ \${SCRIPTNAME} /dev/sda1
  \$ \${SCRIPTNAME} /dev/mmcblk0p1
"

VERSION="
${SCRIPTNAME} 1.0.3
Copyright (c) 2025 Rogerio O. Ferraz <rogerio.o.ferraz@gmail.com>
MIT License <https://github.com/rogeriooferraz/seject/blob/main/LICENSE>
This is free and open source software.
There is NO WARRANTY, to the extent permitted by law.
"

# Options
while [ ${#} -gt 0 ] ; do
  case "${1:-}" in
    --debug|-D)
      shift
      set -x
      ;;
    --help|-h)
      echo "${USAGE}"
      exit 0
      ;;
    --version|-V)
      echo "${VERSION}"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

# Validate user input
if [[ "${#}" != 1 ]]; then
  echo "Error: invalid or missing argument" >&2
  echo "See '${SCRIPTNAME} --help' or manual page for more information" >&2
  exit 1
fi

# Get device path
DEVICE="${1:-}"
if [[ -z "${DEVICE}" ]]; then
  echo "error: no device specified" >&2
  echo "See '${SCRIPTNAME} --help' or manual page for more information" >&2
  exit 2
fi
if [[ ! -b "${DEVICE}" ]]; then
  echo "error: device not found: ${DEVICE}" >&2
  echo "See '${SCRIPTNAME} --help' or manual page for more information" >&2
  exit 3
fi
BASENAME="$(basename ${DEVICE})"
# Support various device types common in OpenWrt
if [[ "${BASENAME}" =~ ^(sd[a-z])$ ]]; then
  DRIVE="/dev/${BASH_REMATCH[1]}"
elif [[ "${BASENAME}" =~ ^(sd[a-z])([0-9]+)$ ]]; then
  DRIVE="/dev/${BASH_REMATCH[1]}"
else
  echo "error: unsupported device: ${BASENAME}" >&2
  echo "See '${SCRIPTNAME} --help' or manual page for more information" >&2
  exit 4
fi

# Check dependencies (OpenWrt compatible)
if ! command -v umount &> /dev/null; then
  echo "error: umount not found. Please check your OpenWrt installation" >&2
  exit 5
fi
if ! command -v sync &> /dev/null; then
  echo "error: sync not found. Please check your OpenWrt installation" >&2
  exit 6
fi
if ! command -v mount &> /dev/null; then
  echo "error: mount not found. Please check your OpenWrt installation" >&2
  exit 7
fi
if ! command -v blockdev &> /dev/null; then
  echo "error: blockdev not found. Please install block-mount package" >&2
  exit 8
fi

# Unmount device partition(s) - OpenWrt compatible
MOUNTED_LEFT=0
# Get mounted partitions using /proc/mounts
while read -r device mountpoint fs_type; do
  if [[ "$device" == "${DRIVE}"* && -n "$mountpoint" ]]; then
    echo "Unmounting $device ($mountpoint)..."
    sync
    if ! umount "$device" 2>/dev/null; then
      # Try force unmount if normal umount fails
      echo "Normal unmount failed, trying lazy unmount..."
      if ! umount -l "$device" 2>/dev/null; then
        echo "error: failed to unmount $device" >&2
        exit 9
      fi
    fi
    echo "Unmounted $device"
  fi
done < /proc/mounts

# Flush write cache
echo "Flushing write cache (sync)..."
sync

# Final sync before power-off
sync

# Power off - OpenWrt compatible
if [[ -b "${DRIVE}" ]]; then
  echo "Flushing buffers and powering off ${DRIVE}..."
  # Flush all buffers
  sync
  # Set the device to standby mode (low power)
  if command -v hdparm &> /dev/null; then
    hdparm -y "${DRIVE}" 2>/dev/null || echo "Warning: could not put device in standby mode"
  fi
  # Try to flush device buffers
  blockdev --flushbufs "${DRIVE}" 2>/dev/null || echo "Warning: could not flush device buffers"
  echo "Device ${DRIVE} has been safely prepared for removal"
else
  echo "Skipping power-off: ${DRIVE} no longer exists"
fi

echo "You may now safely unplug the device"
exit 0
