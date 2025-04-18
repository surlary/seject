# seject - Safely eject USB drives

A command-line utility to safely unmount and power off USB drives.

It ensures data integrity by flushing the write cache, and confirming that no
partitions remain mounted or in use, so the USB drive can be safely unplugged.

The command accepts a single argument, which can be the USB drive device
(e.g. /dev/sdX), or a USB partition device (e.g. /dev/sdXN). In both cases,
the behavior is the same.

## Features

- Automatically unmounts all **mounted partitions** of the USB drive
- Waits and retry until timeout, if any partition is busy or flushing
- Flushes write cache to disk after unmounting
- Uses `udisksctl` to **unmount** and **power off** the USB device without
root privilege (sudo)
- Fails gracefully when necessary (e.g. device busy, non-existent device)

## Why not use '/usr/bin/eject' ?

The legacy `eject` command was made for CD/DVD drives:

- Often doesn’t power off USB drives
- May only unmount one partition
- Leaves disks spinning or LED active

This script ensures:

- All mounted partitions are unmounted
- Pending I/O is flushed with `sync`
- The disk disappears from `lsblk`
- The LED turns off or disk spins down

## Usage Examples

```bash
# Find your USB drive:
$ lsblk -ln -o NAME,SIZE,TYPE,MOUNTPOINT

# Safely eject USB drive by device path:
$ seject /dev/sdX

# Safely eject USB drive by a partition path:
$ seject /dev/sdXN
```

## Requirements

- `udisks2`<br>
udisksctl command, from package version 2.8.0 onwards

- `psmisc`<br>
fuser -s command, from package version 22.21 onwards

- `coreutils`<br>
sync command, from package version 8.25 onwards

- `util-linux`<br>
lsblk command, from package version 2.29 onwards

## Installation on Linux

You may do a manual install, for the main script only:

```bash
cd /tmp
git clone git@github.com:rogeriooferraz/seject.git
sudo cp seject/seject /usr/local/bin/
sudo chmod +x /usr/local/bin/seject
```

Or run apt install (includes man support), for Debian-based distros, such as
Debian, Ubuntu, Linux Mint, Zorin OS, and Pop!_OS, among others.

```bash
cd /tmp
git clone git@github.com:rogeriooferraz/seject.git
sudo apt update
sudo apt install ./seject/deb/safe-eject_1.0-1_all.deb
```

## Tested with

- External USB 3.0 HDDs and SSDs (JMicron / Orico)
- Ubuntu 24.04 LTS with GNOME & X11
- Multi-partition devices

## License

MIT License<br>
This is free software: you are free to change and redistribute it.<br>
There is NO WARRANTY, to the extent permitted by law.

**Project page**: https://github.com/rogeriooferraz/seject
