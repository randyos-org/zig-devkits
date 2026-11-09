# zig-devkits

Zig devkits for [zig-build](https://codeberg.org/emanspeaks/zig-build): the prebuilt Zig with LLVM, Clang and LLD that zig-build bootstraps our Zig from. Each one is `zig+llvm+lld+clang-<host target>-<zig version>`, laid out like upstream's: the LLVM install prefix, plus `bin/zig` and `lib/zig`.

Two kinds live here, one release per version:

- **Mirrors** of upstream Zig's devkits from `https://ziglang.org/deps/`, unchanged, so every host's devkit comes from one place.
- **Builds** for hosts upstream does not publish, made from [zig-bootstrap](https://codeberg.org/ziglang/zig-bootstrap) on our own machines.

This is not upstream's zig-bootstrap, and not affiliated with the Zig project.

## Releases

A release is tagged with the devkit's Zig version (for example `0.18.0-dev.92+1e1964473`). Its assets keep upstream's file names, so a release's download URL can stand in for `https://ziglang.org/deps/`. The assets are:

- `zig+llvm+lld+clang-<host target>-<zig version>.tar.xz` (`.zip` for Windows hosts);
- `SHA256SUMS` for every devkit in the release;
- for a devkit built here, `<devkit>.json`: what it was built from and how.

| Host | Source |
| --- | --- |
| `x86_64-macos-none` | built here (upstream publishes none) |
| every other host upstream's CI uses | mirrored |

## Mirroring

The **Mirror upstream devkits** workflow (`.github/workflows/mirror.yml`, run by hand) takes an upstream Zig branch, tag or commit. `ziglang.org/deps` has no index, so the workflow reads the hosts and the version from upstream Zig's CI scripts (`ci/*.sh`, `ci/*.ps1`) at that ref: those scripts download exactly these devkits. It fills in whatever the release does not have yet.

## Building a devkit

For a host upstream does not publish, on that host:

```sh
git clone https://codeberg.org/ziglang/zig-bootstrap.git
cd zig-bootstrap
git checkout <zig-bootstrap commit>   # zig-build's pin (ZIG_BOOTSTRAP_COMMIT)
./build <target> baseline             # e.g. x86_64-macos-none
```

Then assemble the devkit from `out/`, in upstream's layout:

```sh
d=zig+llvm+lld+clang-<target>-<zig version>
cp -R out/<target>-baseline "$d"                    # the LLVM, Clang and LLD prefix
cp out/zig-<target>-baseline/zig "$d/bin/zig"
cp -R out/zig-<target>-baseline/lib "$d/lib/zig"
tar -cJf "$d.tar.xz" "$d"
```

The `<zig version>` is the Zig that zig-bootstrap builds (`ZIG_VERSION` in its `build` script).

On macOS:

- **Compiler:** build with Apple's clang, `CC=/usr/bin/clang CXX=/usr/bin/clang++`. A nix-darwin host puts GCC first on `PATH`, and GCC fails twice here: it cannot find the SDK's `libz.tbd`, and it miscompiles `zig2`.
- **Sleep:** run the build under `caffeinate -i`.
- **Time:** expect several hours. About 4.5 hours on a 6-core i5-8500B at `CMAKE_BUILD_PARALLEL_LEVEL=6`, most of it the host LLVM.

These steps are meant to move into zig-build as a script ([rstd#271](https://github.com/randyos-org/rstd/issues/271)), with this repo only running and publishing them, as [powerzig-bootstrap](https://github.com/emanspeaks/powerzig-bootstrap) does for PowerPC's LLVM.

## Licenses

This repository's own files are MIT (`LICENSE`). The devkits carry Zig (MIT) and LLVM, Clang and LLD (Apache-2.0 WITH LLVM-exception), each under its own license.
