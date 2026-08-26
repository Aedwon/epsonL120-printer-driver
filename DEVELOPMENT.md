# Development

This document is for contributors and maintainers. End users installing the prebuilt package should follow the main README instead.

## Requirements

- Apple Silicon Mac (`arm64`)
- macOS with CUPS 2.3.x printing tools
- Xcode or Xcode Command Line Tools
- Homebrew `pkg-config`

Install the Homebrew prerequisite with:

```sh
brew install pkg-config
```

Clone the repository into a path without spaces. Gutenprint 5.3.5's older libtool build is not reliable with spaces in the build/prefix path.

## Build

```sh
./build.sh
```

`build.sh`:

1. downloads Gutenprint 5.3.5 from SourceForge;
2. applies compile flags needed by recent Apple SDKs for legacy BSD typedefs used by the older CUPS/Gutenprint code;
3. builds Gutenprint natively for the current Apple Silicon Mac;
4. generates the simplified Epson L120 PPD from `gutenprint.5.3://escp2-l120/simple`;
5. rewrites the PPD to use the project-owned filter path under `/Library/Printers/EpsonL120`.

Generated source and build products stay out of Git.

## Offline verification

```sh
./test-filter.sh
```

This exercises:

```text
text → PDF → Apple cgpdftoraster → Gutenprint escp2-l120 → Epson printer stream
```

It does not send printer data over USB.

A successful run ends with:

```text
=== Offline L120 render passed ===
```

## Development install

With an Epson L120 connected and powered on:

```sh
./install.sh
```

This installs the runtime under `/Library/Printers/EpsonL120` and creates the `Epson_L120` CUPS queue.

A command-line smoke test can then be sent with:

```sh
lp -d Epson_L120 test.pdf
```

## Build the unsigned package

After the build and offline test pass:

```sh
./package.sh
```

The default version is `0.1.0`. Override it with:

```sh
PACKAGE_VERSION=0.1.1 ./package.sh
```

The package builder creates:

```text
dist/
├── EpsonL120-macOS-arm64-<version>.pkg
├── gutenprint-5.3.5-source.tar.xz
└── SHA256SUMS.txt
```

The package is intentionally unsigned and not notarized. It bundles the runtime required by the target Mac, so prebuilt-package users do not need Xcode, Homebrew, `pkg-config`, or a separate Gutenprint installation.

## CI

`.github/workflows/verify.yml` runs on GitHub's standard Apple Silicon `macos-15` runner. It checks shell syntax, builds Gutenprint, runs the offline renderer test, builds the package, and verifies the generated checksums.

The CI workflow never attempts to access a physical printer.

## Releases

`.github/workflows/release.yml` is triggered by tags matching `v*`.

For a release:

1. update `CHANGELOG.md` and `RELEASE_NOTES.md`;
2. ensure `main` is green;
3. tag the release commit, for example `v0.1.0`;
4. push the tag.

The release workflow builds on an arm64 macOS runner and publishes these assets automatically:

- the unsigned `.pkg`;
- the exact Gutenprint source archive used by the build;
- `SHA256SUMS.txt`.

Example:

```sh
git tag -a v0.1.0 -m "Epson L120 macOS driver v0.1.0"
git push origin v0.1.0
```

## Uninstall

From a repository checkout:

```sh
./uninstall.sh
```

From a package installation:

```sh
sudo /Library/Printers/EpsonL120/bin/uninstall-epson-l120
```

## Architecture notes

Gutenprint 5.3.5 predates current Apple SDK behavior. Recent SDKs can hide legacy BSD typedefs such as `u_int`, `u_char`, and `u_short` when older sources include CUPS networking headers. `build.sh` supplies `_DARWIN_C_SOURCE` and force-includes `<sys/types.h>` so Gutenprint can compile with current Apple Clang.

The generated PPD is intentionally not source-controlled. `build.sh` regenerates it from upstream Gutenprint's `escp2-l120` model.

The current PPD/filter driver mechanism is deprecated in CUPS. Future work should treat migration away from legacy PPD/filter drivers as an architectural concern, not merely a packaging change.
