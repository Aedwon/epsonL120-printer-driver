#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFIX="/usr/local/epson-l120-gutenprint"
PPD="$ROOT/build/Epson_L120-Gutenprint.ppd"
FILTER_SRC="$PREFIX/libexec/cups/filter/rastertogutenprint.5.3"
[[ -x "$FILTER_SRC" ]] || FILTER_SRC="$PREFIX/lib/cups/filter/rastertogutenprint.5.3"

[[ -f "$PPD" ]] || { echo "Run ./build.sh first." >&2; exit 1; }
[[ -x "$FILTER_SRC" ]] || { echo "Gutenprint filter not found. Run ./build.sh first." >&2; exit 1; }

mkdir -p "$PREFIX"

# Copy generated PPD into the project prefix for reference.
install -m 0644 "$PPD" "$PREFIX/Epson_L120-Gutenprint.ppd"

# The wrapper sets Gutenprint's XML/module paths before invoking the real filter.
cat > /tmp/rastertoepsonl120.$$ <<WRAP
#!/bin/sh
export STP_DATA_PATH="$PREFIX/share/gutenprint/5.3/xml"
export STP_MODULE_PATH="$PREFIX/lib/gutenprint/5.3/modules"
exec "$FILTER_SRC" "\$@"
WRAP
install -m 0755 /tmp/rastertoepsonl120.$$ /usr/libexec/cups/filter/rastertoepsonl120
rm -f /tmp/rastertoepsonl120.$$

printf '%s\n' "Installed native L120 Gutenprint filter:" "/usr/libexec/cups/filter/rastertoepsonl120"
printf '%s\n' "PPD:" "$PREFIX/Epson_L120-Gutenprint.ppd"
