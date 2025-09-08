#!/bin/sh

set -euo pipefail

SCRIPTNAME="$(basename "$0")"

USAGE="Usage: ${SCRIPTNAME} [OPTIONS] device

Safely eject USB drive in OpenWrt.

ARGUMENTS:
  device         : USB storage device path, e.g., /dev/sdX
                   or USB storage partition path, e.g., /dev/sdXN

OPTIONS:
  -D, --debug    : Enable debug output
  -h, --help     : Display usage information
"

VERSION="${SCRIPTNAME} 1.0.3"

# Options
while [ "$#" -gt 0 ]; do
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
if [ "$#" -ne 1 ]; then
  echo "Error: invalid or missing argument" >&2
  echo "See '${SCRIPTNAME} --help' for more information" >&2
  exit 1
fi

# Get device path
DEVICE="${1:-}"
if [ -z "${DEVICE}" ]; then
  echo "Error: no device specified" >&2
  echo "See '${SCRIPTNAME} --help' for more information" >&2
  exit 2
fi
if [ ! -b "${DEVICE}" ]; then
  echo "Error: device not found: ${DEVICE}" >&2
  echo "See '${SCRIPTNAME} --help' for more information" >&2
  exit 3
fi

# Check if block and fuser are available
if ! command -v block &> /dev/null; then
  echo "Error: block not found. Please ensure block support is installed" >&2
  exit 4
fi
if ! command -v fuser &> /dev/null; then
  echo "Error: fuser not found. Please install psmisc" >&2
  exit 5
fi

# Unmount device partition(s)
MOUNTED_LEFT=0
block umount "${DEVICE}" || {
  echo "Error: failed to unmount ${DEVICE}" >&2
  exit 6
}

# Flush write cache
echo "Flushing write cache (sync)..."
sync

# Power off
echo "Attempting to power off ${DEVICE}..."
if echo 1 > "/sys/block/${DEVICE##*/}/device/delete"; then
  echo "Device ${DEVICE} powered off successfully"
else
  echo "Error: failed to power off device ${DEVICE}" >&2
  exit 7
fi

echo "You may now safely unplug the device"
exit 0
