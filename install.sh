#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="5.3.5"
SOURCE="$ROOT/work/gutenprint-${VERSION}"
PREFIX="/Library/Printers/EpsonL120"
QUEUE="Epson_L120"
PPD_SRC="$ROOT/build/Epson_L120-Gutenprint.ppd"
FILTER_SRC="$SOURCE/src/cups/.libs/rastertogutenprint.5.3"
LIB_SRC="$SOURCE/src/main/.libs/libgutenprint.9.dylib"
XML_SRC="$SOURCE/src/xml"
FILTER_WRAPPER="/usr/libexec/cups/filter/rastertoepsonl120-gutenprint"

for artifact in "$PPD_SRC" "$FILTER_SRC" "$LIB_SRC"; do
  [[ -e "$artifact" ]] || {
    echo "ERROR: missing build artifact: $artifact" >&2
    echo "Run ./build.sh first." >&2
    exit 1
  }
done
[[ -d "$XML_SRC" ]] || { echo "ERROR: Gutenprint XML data missing. Run ./build.sh first." >&2; exit 1; }

DEVICE_URI="${DEVICE_URI:-}"
if [[ -z "$DEVICE_URI" ]]; then
  DEVICE_URI="$(lpinfo -v 2>/dev/null | awk '$1 == "direct" && $2 ~ /^usb:\/\/EPSON\/L120%20Series/ { print $2; exit }')"
fi

if [[ -z "$DEVICE_URI" ]]; then
  echo "ERROR: Epson L120 not detected over USB." >&2
  echo "Connect and power on the printer, then verify with: lpinfo -v | grep -i L120" >&2
  exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
  echo "Administrator access is required to install the CUPS filter and printer queue."
  exec sudo env DEVICE_URI="$DEVICE_URI" /bin/bash "$0" "$@"
fi

FILTER_DST="$PREFIX/bin/rastertogutenprint.5.3"
LIB_DST="$PREFIX/lib/libgutenprint.9.dylib"
XML_DST="$PREFIX/share/gutenprint/5.3/xml"
PPD_DST="$PREFIX/Epson_L120-Gutenprint.ppd"

printf '==> Installing Epson L120 runtime into %s\n' "$PREFIX"
rm -rf "$PREFIX"
install -d -m 0755 "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/share/gutenprint/5.3"
install -m 0755 "$FILTER_SRC" "$FILTER_DST"
install -m 0755 "$LIB_SRC" "$LIB_DST"
cp -R "$XML_SRC" "$XML_DST"
chmod -R a+rX "$PREFIX/share"
install -m 0644 "$PPD_SRC" "$PPD_DST"

# Make the copied binaries independent of the build directory/prefix that
# libtool used while compiling.
install_name_tool -id "$LIB_DST" "$LIB_DST"
OLD_LIB_REF="$(otool -L "$FILTER_DST" | awk '/libgutenprint\.9\.dylib/ { print $1; exit }')"
if [[ -z "$OLD_LIB_REF" ]]; then
  echo "ERROR: installed raster filter does not link to libgutenprint.9.dylib." >&2
  exit 1
fi
if [[ "$OLD_LIB_REF" != "$LIB_DST" ]]; then
  install_name_tool -change "$OLD_LIB_REF" "$LIB_DST" "$FILTER_DST"
fi

cat > "$FILTER_WRAPPER" <<WRAPPER
#!/bin/sh
export STP_DATA_PATH="$XML_DST"
exec "$FILTER_DST" "\$@"
WRAPPER
chown root:wheel "$FILTER_WRAPPER"
chmod 0755 "$FILTER_WRAPPER"

printf '==> Creating CUPS queue %s\n' "$QUEUE"
if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  lpadmin -x "$QUEUE"
fi
lpadmin \
  -p "$QUEUE" \
  -E \
  -v "$DEVICE_URI" \
  -P "$PPD_DST" \
  -o printer-is-shared=false

cupsenable "$QUEUE"
cupsaccept "$QUEUE"

printf '\nInstalled successfully.\n'
printf 'Queue: %s\n' "$QUEUE"
printf 'USB:   %s\n' "$DEVICE_URI"
printf 'PPD:   %s\n' "$PPD_DST"
printf 'Filter:%s\n\n' "$FILTER_WRAPPER"
lpstat -v "$QUEUE"
printf '\nThe printer should now appear in normal macOS print dialogs as Epson_L120.\n'
printf 'A command-line test can be sent with: lp -d %s test.pdf\n' "$QUEUE"
