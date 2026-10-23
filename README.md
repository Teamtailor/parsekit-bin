# parsekit-bin

Prebuilt native gems for [parsekit](https://github.com/scientist-labs/parsekit), published to rubygems.org as `parsekit-bin`. Same code, same version numbers, same `require "parsekit"`; only the gem name differs.

Upstream ships prebuilt gems for `arm64-darwin` and `x86_64-linux` but not `aarch64-linux`: its cross-compile of the bundled Tesseract fails. This repo builds each platform natively on a runner of that architecture instead, so `aarch64-linux` (our production and CI) installs without a Rust toolchain.

No upstream source lives here. `bin/fetch-upstream <version>` downloads the upstream tag tarball into `src/` and renames the gem in the gemspec. The workflow builds from that.

## Releasing

`poll-upstream` runs daily. It builds and publishes the newest upstream version whenever any of its expected platform gems (source, `x86_64-linux`, `aarch64-linux`, `arm64-darwin`) is missing from rubygems.org, so a partial publish is retried the next day. To build a specific version by hand, run the `native-gems` workflow with the version as input.

Publishing uses RubyGems trusted publishing bound to this repo and `.github/workflows/native-gems.yml`; keep that filename. Only runs on `main` publish; a dispatch on any other branch builds and load-tests the gems and stops there. Already published platform gems are skipped, so re-running after a failed leg only pushes what is missing. The darwin gem is published as `arm64-darwin` without the macOS version, because RubyGems only matches a versioned darwin platform on a Ruby built on that exact macOS version.

Linux gems are built on `ubuntu-22.04` runners so they link against glibc 2.35 and load on Debian bookworm (2.36), which the consuming Docker images use; every leg installs and loads the built gem, the Linux ones inside `ruby:4.0-slim-bookworm`. Gems are built with Ruby `4.0` (see `RUBY_VERSION` in the workflow). Bump it together with the consuming apps; a prebuilt gem only installs on the Ruby ABI it was built for.

## Building locally

```
bin/fetch-upstream 0.2.0
bundle install
mkdir -p tessdata && curl -fsSL https://github.com/tesseract-ocr/tessdata_fast/raw/main/eng.traineddata -o tessdata/eng.traineddata
(cd src && TESSDATA_PREFIX="$PWD/../tessdata" bundle exec rake native gem)
ls src/pkg
```
