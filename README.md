# zig-devkits

Zig devkits for [zig-build](https://codeberg.org/emanspeaks/zig-build): the prebuilt Zig with LLVM, Clang and LLD that zig-build bootstraps our Zig from. Each one is `zig+llvm+lld+clang-<host target>-<zig version>`, laid out like upstream's: the LLVM install prefix, plus `bin/zig` and `lib/zig`.

Two kinds live here, one release per version:

- **Mirrors** of upstream Zig's devkits from `https://ziglang.org/deps/`, unchanged, so every host's devkit comes from one place.
- **Builds** for hosts upstream does not publish, made by this repo's workflow from [zig-build](https://codeberg.org/emanspeaks/zig-build)'s cross-build scripts.

This is not upstream's zig-bootstrap, and not affiliated with the Zig project.

## Releases

A release is tagged with the devkit's Zig version (for example `0.18.0-dev.92+1e1964473`). Its assets keep upstream's file names, so a release's download URL can stand in for `https://ziglang.org/deps/`. The assets are:

- `zig+llvm+lld+clang-<host target>-<zig version>.tar.xz` (`.zip` for Windows hosts);
- `SHA256SUMS` for every devkit in the release;
- for a devkit built here, `<devkit>.json`: its inputs (zig-build's `cross-manifest.sh`).

Devkits are only ever release assets, downloaded or built by the workflows; none is stored in the repository.

| Host | Source |
| --- | --- |
| `x86_64-macos-none` | built here (upstream publishes none) |
| every other host upstream's CI uses | mirrored |

## Mirroring

The **Mirror upstream devkits** workflow (`.github/workflows/mirror.yml`, run by hand) takes an upstream Zig branch, tag or commit. `ziglang.org/deps` has no index, so the workflow reads the hosts and the version from upstream Zig's CI scripts (`ci/*.sh`, `ci/*.ps1`) at that ref: those scripts download exactly these devkits. It fills in whatever the release does not have yet.

## Building

The **Build devkits** workflow (`.github/workflows/build.yml`, run by hand) builds the devkit for a host upstream does not publish, with zig-build's scripts, on Linux runners:

1. **Stage3:** `build-stage3.sh`, from upstream's devkit for the runner.
2. **LLVM:** `build-llvm-cross.sh <target> baseline`. It is long, so it is split across two jobs that share a ccache.
3. **Zig:** `build-zig-cross.sh <target> baseline`, zig-src at zig-build's pin. Its version names the release, so the devkit is rebuilt when that pin moves.
4. **Assembly:** upstream's layout, the LLVM prefix plus `bin/zig` and `lib/zig`.
5. **Smoke test:** on the host's own runner (`macos-15-intel` for `x86_64-macos-none`), with Zig and `zig cc` builds.
6. **Publish:** into the release for its version, with its manifest and an updated `SHA256SUMS`.

A run builds only if no release already holds the same `zig_key` from zig-build's `cross-manifest.sh`, so unchanged inputs never rebuild. All build logic lives in zig-build; the workflow only schedules, packages and publishes, as [powerzig-bootstrap](https://github.com/emanspeaks/powerzig-bootstrap) does for PowerPC's LLVM.

zig-bootstrap's own `build` script can make the same devkit natively on the host, including the host LLVM it builds first (about 4.5 hours on a 6-core i5-8500B). On a nix-darwin Mac, set `CC=/usr/bin/clang CXX=/usr/bin/clang++`: GCC, first on `PATH` there, cannot find the SDK's `libz.tbd` and miscompiles `zig2`. Run it under `caffeinate -i`.

## Licenses

This repository's own files are MIT (`LICENSE`). The devkits carry Zig (MIT) and LLVM, Clang and LLD (Apache-2.0 WITH LLVM-exception), each under its own license.
