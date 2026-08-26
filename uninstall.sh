#!/bin/bash
set -euo pipefail

PREFIX="/Library/Printers/EpsonL120"
QUEUE="Epson_L120"

if [[ "$EUID" -ne 0 ]]; then
  exec sudo /bin/bash "$0" "$@"
fi

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "==> Removing CUPS queue $QUEUE"
  lpadmin -x "$QUEUE"
fi

if [[ -d "$PREFIX" ]]; then
  echo "==> Removing driver runtime"
  rm -rf "$PREFIX"
fi

echo "Epson L120 driver removed."
