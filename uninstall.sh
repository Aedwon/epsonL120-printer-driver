#!/bin/bash
set -euo pipefail

PREFIX="/Library/Printers/EpsonL120"
QUEUE="Epson_L120"
FILTER_WRAPPER="/usr/libexec/cups/filter/rastertoepsonl120-gutenprint"

if [[ "$EUID" -ne 0 ]]; then
  exec sudo /bin/bash "$0" "$@"
fi

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "==> Removing CUPS queue $QUEUE"
  lpadmin -x "$QUEUE"
fi

if [[ -e "$FILTER_WRAPPER" ]]; then
  echo "==> Removing CUPS filter wrapper"
  rm -f "$FILTER_WRAPPER"
fi

if [[ -d "$PREFIX" ]]; then
  echo "==> Removing driver runtime"
  rm -rf "$PREFIX"
fi

echo "Epson L120 driver removed."
