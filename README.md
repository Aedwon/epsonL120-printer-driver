# Epson L120 driver for Apple Silicon macOS

This project makes the Epson L120 usable on modern Apple Silicon macOS by building Gutenprint 5.3.5 locally and using Gutenprint's actual `escp2-l120` implementation.

It does **not** reverse-engineer or invent an Epson command stream. The printer data is produced by Gutenprint's Epson ESC/P2 renderer, with macOS CUPS providing the PDF/raster and USB transport layers.

## Status

Physical printing has been verified on a real Epson L120 over USB for:

- black text;
- cyan, magenta, yellow, and black output;
- RGB red, green, and blue output;
- native Apple Silicon (`arm64`) execution.

The build and install scripts are still experimental. macOS/CUPS continues to support the PPD/filter path used here, but that driver architecture is deprecated upstream and may require future maintenance.

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS with CUPS 2.3.x-compatible printing tools
- Xcode or Xcode Command Line Tools
- Homebrew `pkg-config`

Install the one Homebrew prerequisite with:

```sh
brew install pkg-config
```

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
5. rewrites the PPD to use this project's isolated CUPS filter name.

Generated source, build products, raster files, and raw printer streams are ignored by Git.

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

## Install

Connect the Epson L120 by USB, power it on, and confirm that CUPS can see it:

```sh
lpinfo -v | grep -i L120
```

Then run:

```sh
./install.sh
```

The script requests administrator access only when it is ready to install the runtime and create the CUPS queue. It installs this project's files under:

```text
/Library/Printers/EpsonL120
```

and creates an isolated CUPS filter wrapper at:

```text
/usr/libexec/cups/filter/rastertoepsonl120-gutenprint
```

It then creates a printer queue named:

```text
Epson_L120
```

The script does not overwrite a system-wide Gutenprint installation or install a generic `rastertogutenprint.5.3` filter into CUPS.

After installation, the printer should be available to normal macOS print dialogs. A command-line smoke test can be sent with:

```sh
lp -d Epson_L120 test.pdf
```

`test.pdf` is produced by `./test-filter.sh`.

## Uninstall

```sh
./uninstall.sh
```

This removes only the `Epson_L120` queue and files installed by this project.

## Implementation notes

Gutenprint 5.3.5 predates current Apple SDK behavior. Recent SDKs can hide legacy BSD typedefs such as `u_int`, `u_char`, and `u_short` when older sources include the CUPS networking headers. `build.sh` supplies `_DARWIN_C_SOURCE` and force-includes `<sys/types.h>` so Gutenprint can compile with current Apple Clang.

The generated L120 PPD is intentionally not source-controlled; `build.sh` regenerates it directly from the upstream `escp2-l120` model.
