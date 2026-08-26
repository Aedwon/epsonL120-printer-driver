#!/bin/bash
set -euo pipefail
PREFIX="/usr/local/epson-l120-gutenprint"
rm -f /usr/libexec/cups/filter/rastertoepsonl120
rm -rf "$PREFIX"
echo "Removed Epson L120 Gutenprint files installed by this project."
