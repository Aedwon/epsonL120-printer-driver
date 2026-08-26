# Epson L120 macOS driver v0.1.0

First package-install-verified release for using an Epson L120 on Apple Silicon macOS.

## What is included

- `EpsonL120-macOS-arm64-0.1.0.pkg` — unsigned Apple Silicon installer
- `gutenprint-5.3.5-source.tar.xz` — exact Gutenprint source archive distributed with the binary package
- `SHA256SUMS.txt` — SHA-256 checksums for the release assets

## Verified hardware path

This release was installed from the `.pkg` onto an Apple Silicon Mac and physically printed through:

```text
macOS / CUPS
    → Epson_L120 queue
    → Apple raster pipeline
    → Gutenprint escp2-l120
    → macOS USB backend
    → Epson L120
```

Black text and color output were verified on a real Epson L120. The package-created CUPS queue, arm64 filter, and bundled Gutenprint library linkage were also verified after a clean removal of the development installation.

## Installation

Connect and power on the Epson L120, then open the `.pkg` and follow the Installer prompts.

This package is **unsigned and not notarized**. If a downloaded copy is blocked by macOS, verify its checksum first, attempt to open it once, then use **System Settings → Privacy & Security → Open Anyway** for that package.

The target Mac does not need Xcode, Homebrew, `pkg-config`, or a separate Gutenprint installation.

## Scope and limitations

This release currently targets Apple Silicon (`arm64`) and has been physically verified over USB. Intel Macs and other Epson models are not supported by this release.

The implementation uses the legacy CUPS PPD/filter architecture, which is deprecated and may require replacement as future macOS/CUPS releases remove legacy printer-driver support.

This is an independent community project and is not affiliated with or endorsed by Seiko Epson Corporation.
