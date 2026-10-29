# parsekit-bin

Prebuilt native gems for [parsekit](https://github.com/scientist-labs/parsekit), published to rubygems.org as `parsekit-bin`. Same code, same version numbers, same `require "parsekit"`; only the gem name differs, and a fourth version segment marks a rebuild (see below).

Upstream ships prebuilt gems for `arm64-darwin` and `x86_64-linux` but not `aarch64-linux`: its cross-compile of the bundled Tesseract fails. This repo builds each platform natively on a runner of that architecture instead, so `aarch64-linux` (our production and CI) installs without a Rust toolchain.

No upstream source lives here. `bin/fetch-upstream <version>` downloads the upstream tag tarball into `src/` and patches it: it renames the gem in the gemspec and, from `mupdf` 0.8 on, turns on its `base14-fonts` feature, without which PDFs that don't embed their fonts (Helvetica, Times, Courier) parse as `""`. The workflow builds from that.

## Releasing

`poll-upstream` runs daily. It builds and publishes the newest upstream version whenever any of its expected platform gems (source, `x86_64-linux`, `aarch64-linux`, `arm64-darwin`) is missing from rubygems.org, so a partial publish is retried the next day. To build a specific version by hand, run the `native-gems` workflow with the version as input.

### Rebuilds

A published version can't be replaced on rubygems.org. To ship a fixed build of an upstream version, publish it with a fourth segment: `0.2.0.1` is upstream `0.2.0` rebuilt, and sorts above `0.2.0` and below `0.2.1`. `bin/fetch-upstream 0.2.0.1` fetches the `0.2.0` tag and sets `ParseKit::VERSION` to `0.2.0.1`. Add the version to `REBUILDS` in `bin/version-to-build` so the poller builds the rebuild instead of the broken version while that upstream version is the newest.

### Publishing

Publishing uses RubyGems trusted publishing bound to this repo and `.github/workflows/native-gems.yml`; keep that filename. Only runs on `main` publish; a dispatch on any other branch builds and load-tests the gems and stops there. Already published platform gems are skipped, so re-running after a failed leg only pushes what is missing. The darwin gem is published as `arm64-darwin` without the macOS version, because RubyGems only matches a versioned darwin platform on a Ruby built on that exact macOS version.

Linux gems are built on `ubuntu-22.04` runners so they link against glibc 2.35 and load on Debian bookworm (2.36), which the consuming Docker images use. Every leg installs the built gem and reads `fixtures/helvetica.pdf` with `bin/check-pdf-text`, the Linux ones inside `ruby:4.0-slim-bookworm`. Gems are built with Ruby `4.0` (see `RUBY_VERSION` in the workflow). Bump it together with the consuming apps; a prebuilt gem only installs on the Ruby ABI it was built for.

## Building locally

```
bin/fetch-upstream 0.2.0.1
bundle install
mkdir -p tessdata && curl -fsSL https://github.com/tesseract-ocr/tessdata_fast/raw/main/eng.traineddata -o tessdata/eng.traineddata
(cd src && TESSDATA_PREFIX="$PWD/../tessdata" bundle exec rake native gem)
ls src/pkg
```
