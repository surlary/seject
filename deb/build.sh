#!/bin/bash
# build.sh - Build Debian package

# Copyright (c) 2025 Rogerio O. Ferraz <rogerio.o.ferraz@gmail.com>
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

set -e

# Save the current working directory
OLD_DIR="$(pwd)"

# Resolve the absolute path to the script
SCRIPT_PATH="$(realpath -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname -- "${SCRIPT_PATH}")"
SCRIPT_NAME="$(basename -- "${SCRIPT_PATH}")"

# Change to the script's directory
cd -- "${SCRIPT_DIR}" || {
    echo "Error: could not change to script directory" >&2
    exit 1
}

PKG=safe-eject
VERSION=1.0
TAR=${PKG}_${VERSION}.orig.tar.gz
SRCDIR=${PKG}-${VERSION}

# GPG Debian packaging key/email
EMAIL="rogerio.o.ferraz@gmail.com"

echo "[1/6] Preparing source directory..."

# Clean old directory and orig tar
rm -rf ${SRCDIR} ${TAR} ${PKG}_*.{deb,build,buildinfo,changes,dsc}

# Creating debian package build directory
cp -r ${PKG} ${SRCDIR}

# Setting source format to 3.0 (quilt)..."
mkdir -p "${SRCDIR}/debian/source"
echo "3.0 (quilt)" > "${SRCDIR}/debian/source/format"

echo "[2/6] Creating orig tarball (excluding debian/)..."
tar --exclude="${SRCDIR}/debian" -czf "${TAR}" "${SRCDIR}"

echo "[3/6] Building and signing package..."
cd "${SRCDIR}"
dpkg-buildpackage -us -uc -k"${EMAIL}"
cd ..

echo "[4/6] Output:"
ls -lh ${PKG}_${VERSION}*

echo "[5/6] Cleaning temp source dir..."
rm -rf ${SRCDIR}

echo "Build complete"
echo "deb package contents [safe-eject_*.deb]:"
dpkg --contents safe-eject_*.deb

echo "[6/6] Running lintian..."
lintian safe-eject_*.deb || true
echo "Done"

# Return to the original directory
cd -- "${OLD_DIR}" || {
    echo "Error: could not return to original directory" >&2
    exit 1
}
