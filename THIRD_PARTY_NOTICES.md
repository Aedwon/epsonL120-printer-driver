# Third-party notices

## Gutenprint 5.3.5

This project builds and redistributes selected Gutenprint 5.3.5 components used by the Epson L120 CUPS driver path.

Gutenprint is free software distributed under the GNU General Public License, version 2 or later (GPLv2+). The upstream project is maintained at the Gutenprint / Gimp-Print project on SourceForge.

When this project produces a binary `.pkg`, `package.sh` also places the exact upstream `gutenprint-5.3.5.tar.xz` source archive in `dist/` beside the package, together with `SHA256SUMS.txt`. Public binary releases should distribute those source materials with the package.

The installed package also includes Gutenprint's `COPYING` file and, when present in the upstream source tree, `README` and `README.package` under:

```text
/Library/Printers/EpsonL120/share/licenses/Gutenprint
```

No claim of ownership is made over Gutenprint or Epson printer protocols implemented by Gutenprint.
