# g

Simple go version manager, gluten-free.

[![license](https://img.shields.io/github/license/stefanmaric/g.svg)](./LICENSE)

## Why?

Existing version managers build go from source, have too many dependencies, pollute the PATH, and/or require you to use a specific shell environment. `g` aims to be as unobtrusive and portable as possible.

`g` is inspired by [tj/n](https://github.com/tj/n) - which I have contributed to in the past - and borrows some of its code.

## Features

* Works no matter what shell you're using as long as `$GOPATH` and `$GOROOT` are exported, which are not specific to `g` but idiomatic to `go`.
* No need to `source` in your shell config.
* Single bash script that ideally lives where your go binaries live.
* Downloads pre-built binaries so it is fast and...
* ...requires no git, no mercurial, no gcc, no xcode, etc.
* `curl` and `wget` first-class support alike.
* Colorful UI and interactive but safe to pipe and use in automated scripts.


## Requirements

* macOS, Linux or BSD environment - should work just fine on [Bash for Windows (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about).
* Bash 3+, check with `bash --version`
* Either [`curl`](https://en.wikipedia.org/wiki/CURL) **or** [`wget`](https://en.wikipedia.org/wiki/Wget), check with `curl -V` or `wget -V` respectively.


## Install

### Single line

Coming soon.


### Manually

* Make sure to export the `$GOPATH` and `$GOROOT` environment variables and add `$GOPATH/bin` to your `PATH`.
* Grab a copy of the [`./bin/g`](./bin/g) script and put it anywhere available in your `PATH`, inside `$GOPATH/bin/` is a good option.
* Give the script execution rights with `chmod +x $GOPATH/bin/g`.
* Restart your shell session to make sure the env variables are loaded.


## Usage

```
  Usage: g [COMMAND] [options] [args]

  Commands:

    g                           Open interactive UI with installed versions
    g install <version>         Install go <version>
    g install latest            Install or activate the latest go release
    g install -a 386 latest     Force 32 bit architecture
    g install -o darwin latest  Override operating system
    g run <version>             Run a given version of go
    g which <version>           Output bin path for <version>
    g remove <version ...>      Remove the given version(s)
    g prune                     Remove all versions except the current version
    g list                      Output installed go versions
    g list-all                  Output all available go versions
    g help                      Display help information, same as g --help

  Options:

    -h, --help              Display help information and exit
    -v, --version           Output current version of g and exit
    -q, --quiet             Disable curl output (if available)
    -d, --download          Download only
    -c, --no-color          Force disabled color output
    -i, --non-interactive   Prevent promtps
    -o, --os                Override operating system
    -a, --arch              Override system architecture
```


## TODO

- [ ] Improve docs
- [ ] Install and update scripts
- [ ] Write some tests
- [ ] Test it on diff platforms
- [ ] Improve the --quiet and --non-interactive modifiers


## The alternatives

* https://github.com/moovweb/gvm
* https://github.com/kennyp/asdf-golang
* https://github.com/hit9/oo
* https://github.com/andrewkroh/gvm


## Contributing

Please read [CONTRIBUTING.md](./CONTRIBUTING.md). ♥


## License

[MIT](./LICENSE) ♥
