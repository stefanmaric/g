# Changelog

## Unreleased

- Improve performance of switching between different Go versions to nearly instant

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
  * BREAKING: Remove the `--download` option
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

- Initial release
