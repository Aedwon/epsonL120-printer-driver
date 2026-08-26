#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRCROOT="$ROOT/work"
PREFIX="$ROOT/stage"
VERSION="5.3.5"
TARBALL="$SRCROOT/gutenprint-${VERSION}.tar.xz"
URL="https://downloads.sourceforge.net/gimp-print/gutenprint-${VERSION}.tar.xz"

mkdir -p "$SRCROOT"

command -v clang >/dev/null || { echo "clang not found. Run: xcode-select --install" >&2; exit 1; }
command -v cups-config >/dev/null || { echo "cups-config not found." >&2; exit 1; }
command -v curl >/dev/null || { echo "curl not found." >&2; exit 1; }
command -v tar >/dev/null || { echo "tar not found." >&2; exit 1; }

echo "==> Architecture: $(uname -m)"
echo "==> CUPS: $(cups-config --version)"

echo "==> Downloading Gutenprint ${VERSION}..."
if [[ ! -f "$TARBALL" ]]; then
  curl -L --fail --retry 3 -o "$TARBALL" "$URL"
fi

if [[ ! -d "$SRCROOT/gutenprint-${VERSION}" ]]; then
  tar -xf "$TARBALL" -C "$SRCROOT"
fi

cd "$SRCROOT/gutenprint-${VERSION}"

if [[ ! -f Makefile ]]; then
  echo "==> Configuring Gutenprint..."
  # Recent Apple SDKs hide legacy BSD typedefs used by older CUPS/Gutenprint code.
  # Force sys/types.h and Darwin compatibility typedefs into every translation unit.
  export CPPFLAGS="${CPPFLAGS:-} -D_DARWIN_C_SOURCE -include sys/types.h"
  ./configure \
    --prefix="$PREFIX" \
    --disable-static \
    --without-gimp2 \
    --without-gimp2-as-gutenprint \
    --enable-cups-ppds \
    --enable-cups-1_2-enhancements \
    --enable-simplified-cups-ppds \
    --disable-translated-cups-ppds \
    --with-modules=static \
    --disable-rpath
fi

echo "==> Building Gutenprint..."
make -j"$(sysctl -n hw.ncpu)"

echo "==> Installing into staging prefix: $PREFIX"
rm -rf "$PREFIX"
mkdir -p "$PREFIX"
make install

echo "==> Generating L120 PPD..."
mkdir -p "$ROOT/build"
LANG=C "$PREFIX/bin/cups-genppd.5.3" -Z -p "$ROOT/build" escp2-l120

PPD="$ROOT/build/stp-escp2-l120.5.3.ppd"
if [[ ! -f "$PPD" ]]; then
  echo "ERROR: expected PPD not created: $PPD" >&2
  exit 1
fi

cp "$PPD" "$ROOT/build/Epson_L120-Gutenprint.ppd"

echo "==> Done. Generated: $ROOT/build/Epson_L120-Gutenprint.ppd"
