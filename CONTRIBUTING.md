# Contributing

Contributions that improve reliability, compatibility, packaging, diagnostics, or documentation are welcome.

## Before opening a pull request

Run the local verification path on Apple Silicon macOS:

```sh
./build.sh
./test-filter.sh
./package.sh
```

Do not commit generated Gutenprint source/build trees, raster files, printer streams, downloaded archives, or `dist/` artifacts.

The automated GitHub Actions workflow performs the same non-hardware build/package checks on an arm64 macOS runner. CI must never attempt to access a physical printer.

## Bug reports

Please include:

- macOS version;
- Mac model/chip or at least `uname -m`;
- `cups-config --version`;
- whether you installed from a release `.pkg` or built from source;
- exact package/release version;
- whether the printer is detected by `lpinfo -v | grep -i L120`;
- output of `lpstat -p Epson_L120` and `lpstat -v Epson_L120`, when available;
- the exact step that failed and the relevant error output.

The USB device URI can contain a printer serial number. Redact the serial portion before posting logs publicly if you do not want to disclose it.

## Scope

Version 0.1.x targets the Epson L120 on Apple Silicon macOS and is physically verified over USB. Changes for Intel Macs, other Epson models, or non-USB transports should remain clearly separated until they have their own verification evidence.

## Packaging and licensing

The original code and documentation in this repository are licensed under GPL-2.0-or-later. By submitting a contribution, you agree that your contribution may be distributed under that same license.

The release package redistributes Gutenprint components. Keep `THIRD_PARTY_NOTICES.md`, the bundled Gutenprint notices, and the corresponding-source release artifact intact when changing packaging behavior.

Do not publish a binary release package without the corresponding Gutenprint source archive and checksum file produced by `package.sh`.
