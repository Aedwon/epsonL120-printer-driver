# Epson L120 driver for Apple Silicon macOS

This project makes the Epson L120 usable on modern Apple Silicon macOS by building Gutenprint 5.3.5 locally and using Gutenprint's actual `escp2-l120` implementation.

It does **not** reverse-engineer or invent an Epson command stream. The printer data is produced by Gutenprint's Epson ESC/P2 renderer, with macOS CUPS providing the PDF/raster and USB transport layers.

## Status

Physical printing has been verified on a real Epson L120 over USB for:

- black text;
- cyan, magenta, yellow, and black output;
- RGB red, green, and blue output;
- native Apple Silicon (`arm64`) execution;
- the installed `Epson_L120` CUPS queue using `lp -d Epson_L120 test.pdf`.

The complete verified path is:

```text
macOS application / lp
        -> CUPS Epson_L120 queue
        -> Apple PDF-to-raster pipeline
        -> installed Gutenprint escp2-l120 filter
        -> macOS USB backend
        -> Epson L120
```

An unsigned `.pkg` packaging path is included for free distribution without an Apple Developer Program membership. The package itself still needs physical installation testing before it should be treated as a release artifact.

The PPD/filter driver architecture used here is deprecated in CUPS and may require future maintenance.

## Requirements

### To build from source

- Apple Silicon Mac (`arm64`)
- macOS with the CUPS 2.3.x printing tools
- Xcode or Xcode Command Line Tools
- Homebrew `pkg-config`

Install the Homebrew prerequisite with:

```sh
brew install pkg-config
```

### To install a prebuilt package

A target Mac does **not** need Xcode, Homebrew, `pkg-config`, or a separate Gutenprint installation. The package contains the driver runtime it needs. It currently targets Apple Silicon (`arm64`) Macs.

## Build

Clone the repository into a path **without spaces**, then run:

```sh
./build.sh
```

The script:

1. downloads Gutenprint 5.3.5 from SourceForge;
2. applies the compile flags needed by recent Apple SDKs for legacy BSD typedefs used by the older CUPS/Gutenprint code;
3. builds Gutenprint natively for the current Apple Silicon Mac;
4. generates the simplified Epson L120 PPD from `gutenprint.5.3://escp2-l120/simple`;
5. rewrites the PPD to use this project's absolute filter path under `/Library/Printers/EpsonL120`.

Generated source, build products, raster files, raw printer streams, and package artifacts are ignored by Git.

## Offline verification

Before installing anything system-wide, run:

```sh
./test-filter.sh
```

This exercises:

```text
text -> PDF -> Apple cgpdftoraster -> Gutenprint escp2-l120 -> Epson printer stream
```

It does **not** send data to the physical printer.

## Build the unsigned installer package

After `./build.sh` and `./test-filter.sh` pass, run:

```sh
./package.sh
```

The default package version is `0.1.0`. Override it when needed with:

```sh
PACKAGE_VERSION=0.1.1 ./package.sh
```

The script creates:

```text
dist/
├── EpsonL120-macOS-arm64-0.1.0.pkg
├── gutenprint-5.3.5-source.tar.xz
└── SHA256SUMS.txt
```

The `.pkg` is intentionally **unsigned and not notarized**. Creating it requires no paid Apple account.

The package installs its files under:

```text
/Library/Printers/EpsonL120
```

and runs a post-install helper that creates the `Epson_L120` CUPS queue when an Epson L120 is connected over USB. If the printer is not connected during installation, the runtime is still installed; connect the printer later and run:

```sh
sudo /Library/Printers/EpsonL120/bin/setup-queue
```

### Gatekeeper warning for downloaded packages

Because the free package is unsigned and not notarized, macOS may block a copy downloaded from the internet. Only override that warning when you obtained the package from a source you trust and verified its checksum.

After attempting to open the package once, macOS provides the manual override under **System Settings -> Privacy & Security -> Open Anyway**. This is the standard macOS override for software from an unidentified developer.

Locally built packages may not receive the same downloaded-file Gatekeeper treatment because they were created on the Mac rather than downloaded.

## Install directly from the repository

The existing development installer remains available. Connect the Epson L120 by USB, power it on, and confirm that CUPS can see it:

```sh
lpinfo -v | grep -i L120
```

Then run:

```sh
./install.sh
```

The script requests administrator access only when it is ready to install the runtime and create the CUPS queue.

The generated PPD uses an absolute CUPS filter path under `/Library/Printers/EpsonL120`, so the installer does **not** modify `/usr/libexec/cups/filter` and does not overwrite or depend on a separate system-wide Gutenprint installation.

After installation, the verified command-line smoke test is:

```sh
lp -d Epson_L120 test.pdf
```

`test.pdf` is produced by `./test-filter.sh`.

## Uninstall

From a repository checkout:

```sh
./uninstall.sh
```

A packaged installation also contains its own uninstaller:

```sh
sudo /Library/Printers/EpsonL120/bin/uninstall-epson-l120
```

This removes the `Epson_L120` queue, the project-owned runtime under `/Library/Printers/EpsonL120`, and the package receipt when present.

## Redistributing the package

Gutenprint is GPLv2+. Do not publish the binary `.pkg` by itself. `package.sh` copies the exact Gutenprint 5.3.5 source archive used for the build into `dist/` and creates checksums for both files.

For a public release, distribute together:

- the Epson L120 `.pkg`;
- `gutenprint-5.3.5-source.tar.xz`;
- `SHA256SUMS.txt`.

The installed runtime also carries Gutenprint's license/packager notices. See `THIRD_PARTY_NOTICES.md` for details.

## Implementation notes

Gutenprint 5.3.5 predates current Apple SDK behavior. Recent SDKs can hide legacy BSD typedefs such as `u_int`, `u_char`, and `u_short` when older sources include the CUPS networking headers. `build.sh` supplies `_DARWIN_C_SOURCE` and force-includes `<sys/types.h>` so Gutenprint can compile with current Apple Clang.

The generated L120 PPD is intentionally not source-controlled; `build.sh` regenerates it directly from the upstream `escp2-l120` model.
