# Changelog

All notable user-facing changes are documented here.

## Unreleased

### Added

- Explicit GPL-2.0-or-later license for the project's original code and documentation.
- Contribution licensing guidance clarifying that submitted changes are distributed under GPL-2.0-or-later.

## 0.1.0 — 2026-08-27

First physically verified package release candidate for Apple Silicon macOS.

### Added

- Native arm64 build of Gutenprint 5.3.5 for current Apple Silicon macOS.
- Epson L120 support through Gutenprint's upstream `escp2-l120` implementation.
- Generated simplified Epson L120 CUPS PPD.
- Project-owned runtime under `/Library/Printers/EpsonL120`.
- Automatic `Epson_L120` USB queue setup.
- Offline PDF → CUPS raster → Gutenprint render verification.
- Unsigned macOS `.pkg` builder requiring no paid Apple Developer account.
- Bundled uninstaller and queue setup helper.
- Gutenprint source-redistribution archive and SHA-256 checksums alongside package builds.
- GitHub Actions verification and tag-driven release automation.

### Verified

- Physical black/text printing.
- CMYK cyan, magenta, yellow, and black output.
- RGB red, green, and blue output.
- Clean removal of the development installation.
- Fresh installation from `EpsonL120-macOS-arm64-0.1.0.pkg`.
- Automatic USB detection and CUPS queue creation after package install.
- Installed filter is Mach-O arm64.
- Installed filter resolves its bundled `libgutenprint.9.dylib` under `/Library/Printers/EpsonL120`.
- Physical printing through the package-created `Epson_L120` queue.

### Known limitations

- Apple Silicon only.
- USB is the only connection path physically verified.
- The package is unsigned and not notarized; downloaded packages can require a Gatekeeper manual override.
- The underlying CUPS PPD/filter driver architecture is deprecated and may stop working in a future macOS/CUPS release.
