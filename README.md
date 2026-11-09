# zig-devkits

Zig devkits for [zig-build](https://codeberg.org/emanspeaks/zig-build): the prebuilt Zig with LLVM, Clang and LLD that zig-build bootstraps our Zig from. Each one is `zig+llvm+lld+clang-<host triple>-<zig version>`, laid out like upstream's: the LLVM install prefix, plus `bin/zig` and `lib/zig`.

Two kinds live here:

- **Mirrors** of upstream Zig's devkits from `https://ziglang.org/deps/`, unchanged, so every host's devkit comes from one place.
- **Builds** for hosts upstream does not publish, made by this repo's workflow from [zig-build](https://codeberg.org/emanspeaks/zig-build)'s cross-build scripts.

This is not upstream's zig-bootstrap, and not affiliated with the Zig project.

## Which devkit to use: `devkits.json`

`devkits.json` on `main` is the lookup: for each host triple, the devkit to use. Releases are immutable, so an update for some hosts is a new release, and only this file says which release each host takes now. The workflows update it after every publish.

```json
{
  "devkits": {
    "x86_64-linux-musl": {
      "version": "0.18.0-dev.92+1e1964473",
      "source": "upstream",
      "release": "upstream-0.18.0-dev.92+1e1964473",
      "asset": "zig+llvm+lld+clang-x86_64-linux-musl-0.18.0-dev.92+1e1964473.tar.xz",
      "url": "https://github.com/randyos-org/zig-devkits/releases/download/upstream-0.18.0-dev.92%2B1e1964473/zig%2Bllvm%2Blld%2Bclang-x86_64-linux-musl-0.18.0-dev.92%2B1e1964473.tar.xz",
      "sha256": "..."
    }
  }
}
```

A built devkit (`"source": "built"`) also names its `manifest`, the `.json` asset listing its inputs. Read the file at `main` for the newest, or at a commit of this repository to pin a set.

## Releases

Releases are immutable: once published, nothing in one changes.

| Release | Holds |
| --- | --- |
| `upstream-<version>` | every devkit upstream Zig's CI uses at that version, and `SHA256SUMS` |
| `<host triple>-<version>` | one devkit built here, its `.json` manifest, and `SHA256SUMS`; a later build of the same version takes a `.2`, `.3`, ... suffix |

Assets keep upstream's file names, `zig+llvm+lld+clang-<host triple>-<zig version>.tar.xz` (`.zip` for Windows hosts). Devkits are only ever release assets, downloaded or built by the workflows; none is stored in the repository.

## Mirroring

The **Mirror upstream devkits** workflow (`.github/workflows/mirror.yml`) runs nightly against upstream Zig's `master`, or by hand for any branch, tag or commit. `ziglang.org/deps` has no index, so it reads the hosts and the version from upstream Zig's CI scripts (`ci/*.sh`, `ci/*.ps1`) at that ref: those scripts download exactly these devkits.

A version already mirrored is skipped. A new one is filled into a draft one devkit at a time, then published, and its hosts in `devkits.json` are pointed at it.

## Building

The **Build devkits** workflow (`.github/workflows/build.yml`, run by hand) builds the devkit for a host upstream does not publish, with zig-build's scripts, on Linux runners:

1. **Stage3:** `build-stage3.sh`, from upstream's devkit for the runner.
2. **LLVM:** `build-llvm-cross.sh <target> baseline`. It is long, so it is split across two jobs that share a ccache.
3. **Zig:** `build-zig-cross.sh <target> baseline`, zig-src at zig-build's pin. Its version names the release, so the devkit is rebuilt when that pin moves.
4. **Assembly:** upstream's layout, the LLVM prefix plus `bin/zig` and `lib/zig`.
5. **Smoke test:** on the host's own runner (`macos-15-intel` for `x86_64-macos-none`), with Zig and `zig cc` builds.
6. **Publish:** as its own release, with its manifest and `SHA256SUMS`, then `devkits.json` points its host at it.

A run builds only if no release already holds the same `zig_key` from zig-build's `cross-manifest.sh`, so unchanged inputs never rebuild. All build logic lives in zig-build; the workflow only schedules, packages and publishes, as [powerzig-bootstrap](https://github.com/emanspeaks/powerzig-bootstrap) does for PowerPC's LLVM.

zig-bootstrap's own `build` script can make the same devkit natively on the host, including the host LLVM it builds first (about 4.5 hours on a 6-core i5-8500B). On a nix-darwin Mac, set `CC=/usr/bin/clang CXX=/usr/bin/clang++`: GCC, first on `PATH` there, cannot find the SDK's `libz.tbd` and miscompiles `zig2`. Run it under `caffeinate -i`.

## Licenses

This repository's own files are MIT (`LICENSE`). The devkits carry Zig (MIT) and LLVM, Clang and LLD (Apache-2.0 WITH LLVM-exception), each under its own license.
