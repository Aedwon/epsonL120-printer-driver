#!/bin/bash
set -euo pipefail

PREFIX="/Library/Printers/EpsonL120"
QUEUE="Epson_L120"
PACKAGE_ID="com.aedwon.epsonl120.driver"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

if [[ "$EUID" -ne 0 ]]; then
  exec sudo /bin/bash "$0" "$@"
fi

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "==> Removing CUPS queue $QUEUE"
  lpadmin -x "$QUEUE"
fi

if pkgutil --pkg-info "$PACKAGE_ID" >/dev/null 2>&1; then
  echo "==> Forgetting installer receipt $PACKAGE_ID"
  pkgutil --forget "$PACKAGE_ID" >/dev/null || true
fi

if [[ -d "$PREFIX" ]]; then
  echo "==> Removing driver runtime"
  rm -rf "$PREFIX"
fi

echo "Epson L120 driver removed."
