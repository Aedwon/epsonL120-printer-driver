#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRCROOT="$ROOT/work"
VERSION="5.3.5"
SOURCE="$SRCROOT/gutenprint-${VERSION}"
TARBALL="$SRCROOT/gutenprint-${VERSION}.tar.xz"
URL="https://downloads.sourceforge.net/gimp-print/gutenprint-${VERSION}.tar.xz"
TARGET_PREFIX="/Library/Printers/EpsonL120"
BUILD_DIR="$ROOT/build"
PPD="$BUILD_DIR/Epson_L120-Gutenprint.ppd"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: this project currently targets macOS only." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: this build is currently verified only on Apple Silicon (arm64)." >&2
  exit 1
fi

# Gutenprint 5.3.5's libtool build does not reliably handle spaces in its prefix/build path.
if [[ "$ROOT" == *" "* ]]; then
  echo "ERROR: move the repository to a path without spaces before building." >&2
  exit 1
fi

for tool in clang cups-config curl tar make pkg-config; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: required tool not found: $tool" >&2
    [[ "$tool" == "pkg-config" ]] && echo "Install it with: brew install pkg-config" >&2
    exit 1
  }
done

echo "==> Architecture: $(uname -m)"
echo "==> CUPS: $(cups-config --version)"
echo "==> Gutenprint: ${VERSION}"

mkdir -p "$SRCROOT" "$BUILD_DIR"

if [[ ! -f "$TARBALL" ]]; then
  echo "==> Downloading Gutenprint ${VERSION}..."
  curl -L --fail --retry 3 -o "$TARBALL" "$URL"
else
  echo "==> Using cached Gutenprint archive."
fi

if [[ ! -d "$SOURCE" ]]; then
  echo "==> Extracting Gutenprint..."
  tar -xf "$TARBALL" -C "$SRCROOT"
fi

cd "$SOURCE"

# Recent Apple SDKs hide legacy BSD typedefs used by Gutenprint's CUPS code.
export CPPFLAGS="${CPPFLAGS:-} -D_DARWIN_C_SOURCE -include sys/types.h"

needs_configure=1
if [[ -f Makefile && -f config.summary ]] && grep -Fq "$TARGET_PREFIX" config.summary; then
  needs_configure=0
fi

if [[ "$needs_configure" -eq 1 ]]; then
  if [[ -f Makefile ]]; then
    echo "==> Reconfiguring Gutenprint for the final install prefix..."
    make distclean >/dev/null 2>&1 || true
  else
    echo "==> Configuring Gutenprint..."
  fi

  ./configure \
    --prefix="$TARGET_PREFIX" \
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

DRIVER="$SOURCE/src/cups/.libs/gutenprint.5.3"
FILTER="$SOURCE/src/cups/.libs/rastertogutenprint.5.3"
LIB="$SOURCE/src/main/.libs/libgutenprint.9.dylib"

for artifact in "$DRIVER" "$FILTER" "$LIB"; do
  [[ -f "$artifact" ]] || {
    echo "ERROR: expected build artifact not found: $artifact" >&2
    exit 1
  }
done

[[ "$(file "$FILTER")" == *"arm64"* ]] || {
  echo "ERROR: rastertogutenprint.5.3 is not an arm64 executable." >&2
  exit 1
}

echo "==> Generating Epson L120 PPD from Gutenprint's escp2-l120 model..."
RAW_PPD="$BUILD_DIR/L120-Gutenprint.raw.ppd"
STP_DATA_PATH="$SOURCE/src/xml" \
STP_MODULE_PATH="$SOURCE/src/main/.libs:$SOURCE/src/main" \
DYLD_LIBRARY_PATH="$SOURCE/src/main/.libs" \
  "$DRIVER" cat "gutenprint.5.3://escp2-l120/simple" > "$RAW_PPD"

# Use a project-specific CUPS filter name so we never overwrite or depend on a
# system-wide Gutenprint installation. Maintenance command support is omitted;
# normal document printing only needs the raster filter.
sed \
  -e '/application\/vnd\.cups-command.*commandtoepson/d' \
  -e 's/rastertogutenprint\.5\.3/rastertoepsonl120-gutenprint/g' \
  "$RAW_PPD" > "$PPD"
rm -f "$RAW_PPD"

grep -Fq '*ModelName:     "Epson L120"' "$PPD" || {
  echo "ERROR: generated PPD is not for Epson L120." >&2
  exit 1
}
grep -Fq 'application/vnd.cups-raster 100 rastertoepsonl120-gutenprint' "$PPD" || {
  echo "ERROR: generated PPD does not reference the project filter." >&2
  exit 1
}

echo "==> Build complete."
echo "    PPD: $PPD"
echo "    Filter: $FILTER"
echo "    Next: ./test-filter.sh"
