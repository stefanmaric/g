# Changelog

## Unreleased


## 1.0.0 - 2026-05-26

This release makes `g` safer, more reliable, and easier to install, while keeping the same tiny POSIX shell script you can inspect, copy, and patch.

`g` is a simple Go version manager, gluten-free. It installs official prebuilt Go archives as an unprivileged user, keeps your environment simple, and avoids shims, plugins, daemons, and runtime dependencies.

Release highlights include:

- **Official Go metadata** for version discovery and archive selection
- **SHA-256 verification** before extracting downloaded Go archives
- **Archive mirror support** with upstream metadata as the trust source
- **Hardened installer behavior** across common shells and Linux distributions
- **GitHub Release assets** for fresh installs and self-upgrades
- **Clearer errors and recovery guidance** for unsupported platforms and incomplete installs
- **Expanded CI coverage** across pinned Linux environments
- **Automated release publishing** for future releases

### Upgrade now

If you already have `g` installed, upgrade with:

```sh
g self-upgrade
```

For a fresh install:

```sh
curl -fsSL https://github.com/stefanmaric/g/releases/latest/download/install | sh
```

Or with `wget`:

```sh
wget -qO- https://github.com/stefanmaric/g/releases/latest/download/install | sh
```

### Official Go metadata

`g` now uses Go's official download metadata instead of scraping version information from HTML.

That means version discovery, archive selection, platform overrides, unstable releases, and checksum verification now all come from the same upstream source of truth.

### Verified downloads

Downloaded Go archives are now verified with SHA-256 checksums from official Go metadata before extraction.

If a download is corrupted, incomplete, or unexpected, `g` stops before it can become an active Go installation.

### Archive mirrors

You can now download Go archives from a mirror while still trusting official Go metadata for version and checksum information.

```sh
G_GO_ARCHIVE_URL=https://mirror.example/golang g install latest
```

Or per command:

```sh
g install latest --archive-url https://mirror.example/golang
```

### A tougher installer

The installer now handles more real-world systems and shells, including environments without `/etc/shells`, improved `ash` and `dash` setup guidance, fixed `tcsh` detection, duplicate shell selection prevention, and safer alias collision handling.

The goal is still the same: configure `GOROOT`, `GOPATH`, and `$GOPATH/bin` with as little magic as possible.

### GitHub Release assets

Fresh installs and self-upgrades now use GitHub Release assets instead of deprecated `git.io` short links.

This makes the install path more transparent, inspectable, and aligned with how releases are published.

### Better CLI resilience

`g` now reports clearer errors for unknown operating systems, unknown architectures, unsupported Go archive combinations, incomplete installs, and missing `$GOPATH/bin` entries in `PATH`.

This release also adds familiar command aliases:

```sh
g use latest
g fetch 1.22.2
g ls
g rm 1.21.9
g self-update
```

### CI and releases

The test suite now covers more metadata, checksum, installer, shell, and smoke-test behavior. CI also runs across pinned Linux environments to catch portability issues earlier.

Future releases are now prepared through a release PR and published automatically after merge.

## 0.11.0 - 2026-05-26

- Upgrade all dev dependencies and CI environment
- Replace ad-hoc Github Actions based tests with sharness
- Replace HTML parsing with Go metadata version discovery
- Add custom Go archive mirror support
- Verify Go archive checksums before extracting downloads
- Replace installed version on explicit arch override mismatch
- Support installing on systems without /etc/shells
- Prevent duplicated shell selection during install
- Suppress shell alias stderr logs during install
- Add common command aliases
- Fix tcsh shell detection during install
- Add missing items to gitignore
- Increase g-install test coverage
- Improve ash/dash ENV install guidance
- Improve handling of unknown version, OS, or architecture
- Match GOPATH bin as an exact PATH entry
- Improve incomplete install recovery guidance
- Improve README
- Expand CI test coverage across Linux distros
- Add automated release process
- Ensure smoke tests use local scripts for bootstrap URLs
- Improve install and download output layouts
- Fix automated release process

## 0.10.0 - 2023-06-10

- Add description and website to help command
- Fix Github Actions tests workflow on newer versions of Ubuntu
- Fix g not activating selected version when system one is available

## 0.9.1 - 2022-10-23

- Fix the grep warning: stray \ before " with the latest releases of grep (#22, thanks @wintermi)

## 0.9.0 - 2021-03-19

- Improve switching Go versions performance to nearly instant (#19, thanks @jimeh)
- Add support for darwin-arm64 (M1 chips) (#20, thanks @joelanford)
- Tweak docs, guidelines, and configs to make it easier to contribute
- Format all documents with Prettier for consistency
- Add Github template for BUG reports
- Update screencast with more recent version of g

## 0.8.1 - 2021-03-17

- Fix shellcheck download in Makefile
- Upgrade shellcheck from v0.7.0 to v0.7.1 and fix new lint errors
- Upgrade shfmt from v3.0.0 to v3.2.4, no format changes introduced
- Introduce a Github Actions workflow file with lint only for now
- Fix g breaking on missing $TERM var in non-interactive systems
- Add basic tests to the Github Actions workflow

## 0.8.0 - 2019-12-24

- Fix arch detection bug in MacOS with coreutils (#15, thanks @ddlees)
- Document decisions around architecture detection
- Add support for arm64, ppc64l, and s390x arch detection

## 0.7.1 - 2019-12-22

- Fix self-upgrade failing due to typo
  - If you upgraded to the 0.7.0 already, you will need to run the install script again

## 0.7.0 - 2019-12-18

- Warn users about existing go installations
- Improve self-upgrade script
- Improve previous installation detection on g-install
- Make self-upgrade throw if g was not installed via g-install
- Add alias collision detection and setup helper (#11, thanks @alvinmatias69)
- Add `download` and `set` commands (#12, thanks @feualpha)
  - BREAKING: Remove the `--download` option
- Add Makefile with lint and format targets for better DX
- Fix shellcheck lint errors
- Format source code using make format
- Improve and update docs to reflect latest contributions

## 0.6.0 - 2019-10-13

- Make g POSIX compatible and use `sh` instead of `bash`
- Cleanup and normalize `g` code
- Make g-install POSIX compatible as well
- Fix g-install breaking on envs without $SHELL
- Fix g breaking when using non-GNU `wget`
- Add handling of misconfigured $GOPATH/bin
- Add support for ash, dash, csh, and tcsh to g-install
- Fix user input source for g-install
- Fix and normalize error logging
- Fix POSIX syntax error on BIN_DIR check
- Fix `stty` command breaking on MacOS
- Fix version listing broken with BSD version of `find`
- Fix IFs using `command` exiting the script due to errexit
- Update docs to reflect latest changes and update roadmap

## 0.5.0 - 2019-07-08

- Add support for listing and installing unstable versions
- Prevent bugs in config files without final newline
- Ensure the modified PATH is exported on bash and zsh
- Prevent multiple selection of the same shell in g-install
- Improve the --quiet modifier
- Normalize messages styles and wording
- Support double-dash to signal end-of-params
- Tweak README file
- Offer to install latest go version after installing g
- Install requested version when `g run` cannot find it. See #3
- Warn about installing on a non-default path. See #5
- Add goenv to the alternatives list on README
- Add instructions for removal on README
- Make the detection of previously installed g stricter

## 0.4.0 - 2019-02-17

- Improve handling of unstable versions
- Implement proper non-interactive mode for install script
- Improve the install script to also double as updater
- Add self-upgrade command
- Document how to upgrade on README

## 0.3.0 - 2018-07-28

- Fix visual glitch while getting remote versions list
- Fix activation error on MacOS because of `cp` and `ln` long params
- Fix unbound var error on install script on MacOS
- Exclude beta version from version list
  - Beta versions can still be installed if you provide the version, e.g. `1.11beta2`

## 0.2.0 - 2018-04-22

- Improve documentation
- Add install script
- BREAKING: short option for `--non-interactive` went from `-i` to `-y`
- Improve logic to check for valid download URLs
- Improve code style and good practices
- Clear Go dist files before activating new version
- Place versions dir inside `$GOROOT` instead of `$GOPATH`
- Use symbolic links for go binaries, instead of hard links
- Fix typo in usage docs by Angel Perez <iAngel.p93@gmail.com>

## 0.1.0 - 2018-04-08

- Initial release
