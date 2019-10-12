# Changelog

## Unreleased

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
  * Beta versions can still be installed if you provide the version, e.g. `1.11beta2`

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

### Added
- Initial release
