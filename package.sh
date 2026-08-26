#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
GUTENPRINT_VERSION="5.3.5"
PACKAGE_VERSION="${PACKAGE_VERSION:-0.1.0}"
PACKAGE_ID="com.aedwon.epsonl120.driver"
PREFIX="/Library/Printers/EpsonL120"
SOURCE="$ROOT/work/gutenprint-${GUTENPRINT_VERSION}"
TARBALL="$ROOT/work/gutenprint-${GUTENPRINT_VERSION}.tar.xz"
PPD="$ROOT/build/Epson_L120-Gutenprint.ppd"
FILTER="$SOURCE/src/cups/.libs/rastertogutenprint.5.3"
LIB="$SOURCE/src/main/.libs/libgutenprint.9.dylib"
XML="$SOURCE/src/xml"
DIST="$ROOT/dist"
PKGWORK="$ROOT/build/package"
PKGROOT="$PKGWORK/root"
SCRIPTS="$PKGWORK/scripts"
FINAL_PKG="$DIST/EpsonL120-macOS-arm64-${PACKAGE_VERSION}.pkg"
SOURCE_COPY="$DIST/gutenprint-${GUTENPRINT_VERSION}-source.tar.xz"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: package creation is currently supported only on Apple Silicon macOS." >&2
  exit 1
fi

for tool in pkgbuild install_name_tool otool shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: required macOS tool not found: $tool" >&2
    exit 1
  }
done

for artifact in "$PPD" "$FILTER" "$LIB" "$TARBALL"; do
  [[ -e "$artifact" ]] || {
    echo "ERROR: missing build artifact: $artifact" >&2
    echo "Run ./build.sh first." >&2
    exit 1
  }
done
[[ -d "$XML" ]] || { echo "ERROR: Gutenprint XML data is missing. Run ./build.sh first." >&2; exit 1; }
[[ -f "$SOURCE/COPYING" ]] || { echo "ERROR: Gutenprint COPYING file not found." >&2; exit 1; }

rm -rf "$PKGWORK"
mkdir -p \
  "$PKGROOT$PREFIX/bin" \
  "$PKGROOT$PREFIX/libexec" \
  "$PKGROOT$PREFIX/lib" \
  "$PKGROOT$PREFIX/share/gutenprint/5.3" \
  "$PKGROOT$PREFIX/share/licenses/Gutenprint" \
  "$SCRIPTS" \
  "$DIST"

FILTER_STAGE="$PKGROOT$PREFIX/libexec/rastertogutenprint.5.3"
LIB_STAGE="$PKGROOT$PREFIX/lib/libgutenprint.9.dylib"
PPD_STAGE="$PKGROOT$PREFIX/Epson_L120-Gutenprint.ppd"
WRAPPER_STAGE="$PKGROOT$PREFIX/bin/rastertoepsonl120-gutenprint"
SETUP_STAGE="$PKGROOT$PREFIX/bin/setup-queue"
UNINSTALL_STAGE="$PKGROOT$PREFIX/bin/uninstall-epson-l120"
FINAL_LIB="$PREFIX/lib/libgutenprint.9.dylib"
FINAL_FILTER="$PREFIX/libexec/rastertogutenprint.5.3"
FINAL_XML="$PREFIX/share/gutenprint/5.3/xml"

install -m 0755 "$FILTER" "$FILTER_STAGE"
install -m 0644 "$LIB" "$LIB_STAGE"
install -m 0644 "$PPD" "$PPD_STAGE"
cp -R "$XML" "$PKGROOT$PREFIX/share/gutenprint/5.3/xml"
chmod -R a+rX "$PKGROOT$PREFIX/share/gutenprint"

install -m 0644 "$SOURCE/COPYING" "$PKGROOT$PREFIX/share/licenses/Gutenprint/COPYING"
[[ -f "$SOURCE/README.package" ]] && install -m 0644 "$SOURCE/README.package" "$PKGROOT$PREFIX/share/licenses/Gutenprint/README.package"
[[ -f "$SOURCE/README" ]] && install -m 0644 "$SOURCE/README" "$PKGROOT$PREFIX/share/licenses/Gutenprint/README"

cat > "$WRAPPER_STAGE" <<WRAPPER
#!/bin/sh
export STP_DATA_PATH="$FINAL_XML"
exec "$FINAL_FILTER" "\$@"
WRAPPER
chmod 0755 "$WRAPPER_STAGE"

install -m 0755 "$ROOT/packaging/setup-queue" "$SETUP_STAGE"
install -m 0755 "$ROOT/uninstall.sh" "$UNINSTALL_STAGE"
install -m 0755 "$ROOT/packaging/postinstall" "$SCRIPTS/postinstall"

# Rewrite the staged Mach-O references to the paths they will have after install.
install_name_tool -id "$FINAL_LIB" "$LIB_STAGE"
OLD_LIB_REF="$(otool -L "$FILTER_STAGE" | awk '/libgutenprint\.9\.dylib/ { print $1; exit }')"
if [[ -z "$OLD_LIB_REF" ]]; then
  echo "ERROR: staged raster filter does not link to libgutenprint.9.dylib." >&2
  exit 1
fi
if [[ "$OLD_LIB_REF" != "$FINAL_LIB" ]]; then
  install_name_tool -change "$OLD_LIB_REF" "$FINAL_LIB" "$FILTER_STAGE"
fi

otool -L "$FILTER_STAGE" | grep -Fq "$FINAL_LIB" || {
  echo "ERROR: staged raster filter was not relinked to the packaged Gutenprint library." >&2
  exit 1
}

grep -Fq "application/vnd.cups-raster 100 $PREFIX/bin/rastertoepsonl120-gutenprint" "$PPD_STAGE" || {
  echo "ERROR: PPD does not reference the packaged L120 filter wrapper." >&2
  exit 1
}

rm -f "$FINAL_PKG"
pkgbuild \
  --root "$PKGROOT" \
  --scripts "$SCRIPTS" \
  --identifier "$PACKAGE_ID" \
  --version "$PACKAGE_VERSION" \
  --install-location / \
  --ownership recommended \
  "$FINAL_PKG"

# Gutenprint is GPLv2+. Keep the exact upstream source archive beside any binary package.
cp "$TARBALL" "$SOURCE_COPY"

(
  cd "$DIST"
  shasum -a 256 \
    "$(basename "$FINAL_PKG")" \
    "$(basename "$SOURCE_COPY")" \
    > SHA256SUMS.txt
)

printf '\n=== Unsigned package built ===\n'
printf 'Package: %s\n' "$FINAL_PKG"
printf 'Source:  %s\n' "$SOURCE_COPY"
printf 'Hashes:  %s\n' "$DIST/SHA256SUMS.txt"
printf '\nPayload summary:\n'
pkgutil --payload-files "$FINAL_PKG" | sed -n '1,40p'
printf '\nThis package is intentionally unsigned and not notarized.\n'
printf 'For public redistribution, publish the package together with the Gutenprint source archive and SHA256SUMS.txt.\n'
