# seject - Safely eject USB drive

A command-line utility to safely unmount and poweroff USB mass-storage devices.

A bash script that mimics the behavior of “Safely Remove USB Drive” in modern
Linux Desktops. It unmounts all partitions, flushes write cache, and powers off
the USB drive, using udisks2 under the hood.

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

## Usage

```bash
seject [OPTIONS] device

ARGUMENTS:
  device         : USB storage device path, e.g., /dev/sdX
                   or USB storage partition path, e.g., /dev/sdXN

OPTIONS:
  -d, --debug    : Enable debug output
  -h, --help     : Display usage information
  -v, --version  : Show current version
```

## Examples

```bash
# Display usage information:
$ seject --help

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

## Install

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
sudo apt install ./seject/deb/safe-eject_1.0-2_all.deb
```

## Uninstall

Uninstalling a manual install:

```bash
rm -rf /tmp/seject
sudo rm /usr/local/bin/seject
```

Uninstalling an apt install:

```bash
rm -rf /tmp/seject
sudo apt update
sudo apt remove safe-eject
```

## Testing

Tested on **Ubuntu 24.04** with **GNOME** desktop environment:

Covered use cases:
- External USB 3.0 HDDs and SSDs (JMicron / Orico)
- Multi-partition devices

## License

This project is licensed under the MIT License.<br>
It is free and open source software: you can freely use it, change it, and redistribute it.<br>
There is NO WARRANTY, to the extent permitted by law.

**Project page**: https://github.com/rogeriooferraz/seject

## Author

Rogerio O. Ferraz (<rogerio.o.ferraz@gmail.com>)
