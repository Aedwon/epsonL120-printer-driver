# Epson L120 macOS native Gutenprint build (bring-up 0.3)

This package builds the upstream Gutenprint 5.3.5 driver stack locally on Apple Silicon and generates the real `escp2-l120` PPD (model 80), rather than using a hand-written Epson command stream.

### Important build fix

Recent Apple SDKs can hide legacy BSD typedefs (`u_int`, `u_char`, `u_short`) that older CUPS/Gutenprint sources expect. `build.sh` now forces `<sys/types.h>` and `_DARWIN_C_SOURCE` into the compile flags.

### Build

1. Keep the Epson L120 disconnected.
2. Install the prerequisite once:

```sh
brew install pkg-config
```

3. From this directory run:

```sh
./build.sh
```

If a previous failed build left `work/gutenprint-5.3.5/`, remove just that source tree before retrying so configure runs again:

```sh
rm -rf work/gutenprint-5.3.5
```

Then run `./build.sh` again.

### Test

Only after the build succeeds:

```sh
./test-filter.sh
```

Do not install or connect the printer until the generated stream has been checked.
