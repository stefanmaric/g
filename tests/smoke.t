#!/bin/sh

test_description='g smoke tests'

. "${SHARNESS_PATH:-./.tmp/sharness.sh}"

repo_root="$SHARNESS_BUILD_DIRECTORY"
mock_path="$PWD/smoke-mocks"
real_curl=$(command -v curl)
real_wget=$(command -v wget)
GOPATH="$HOME/go"
GOROOT="$HOME/.go"
export GOPATH GOROOT

create_smoke_mocks() {
  mkdir -p "$mock_path" &&
  if [ -n "$real_curl" ]; then
    cat >"$mock_path/curl" <<- EOF
	#!/bin/sh
	set -o errexit
	set -o nounset

	for item in "\$@"; do
	  case \$item in
	    https://git.io/g-install) cat "$repo_root/bin/install"; exit 0 ;;
	    https://git.io/g-bin) cat "$repo_root/bin/g"; exit 0 ;;
	  esac
	done

	exec "$real_curl" "\$@"
EOF
    chmod +x "$mock_path/curl"
  fi

  if [ -n "$real_wget" ]; then
    cat >"$mock_path/wget" <<- EOF
	#!/bin/sh
	set -o errexit
	set -o nounset

	for item in "\$@"; do
	  case \$item in
	    https://git.io/g-install) cat "$repo_root/bin/install"; exit 0 ;;
	    https://git.io/g-bin) cat "$repo_root/bin/g"; exit 0 ;;
	  esac
	done

	exec "$real_wget" "\$@"
EOF
    chmod +x "$mock_path/wget"
  fi
}

previous_stable_version() {
  "$real_curl" --fail --silent --show-error --location 'https://go.dev/dl/?mode=json' \
    | grep -Eo '"version":[[:space:]]*"go[[:digit:].]+"' \
    | cut -d '"' -f 4 \
    | sed -n '2s/^go//p'
}

run_with_g_env() {
  env \
    HOME="$HOME" \
    GOPATH="$GOPATH" \
    GOROOT="$GOROOT" \
    REAL_CURL="$real_curl" \
    REAL_WGET="$real_wget" \
    PATH="$mock_path:$GOPATH/bin:$PATH" \
    SHELL=/bin/bash \
    sh -c "$1"
}

test_expect_success 'install script configures g' '
  create_smoke_mocks &&
  env \
    HOME="$HOME" \
    GOPATH="$GOPATH" \
    GOROOT="$GOROOT" \
    REAL_CURL="$real_curl" \
    REAL_WGET="$real_wget" \
    PATH="$mock_path:$PATH" \
    SHELL=/bin/bash \
    sh -c "curl -sSL https://git.io/g-install | sh -s -- -y bash"
'

test_expect_success 'g reports its version' '
  output=$(run_with_g_env "g --version") &&
  test "$output" = "0.10.0"
'

test_expect_success 'go is installed by g and present on PATH' '
  output=$(run_with_g_env "go version") &&
  case "$output" in go*) true ;; *) false ;; esac &&
  path=$(run_with_g_env "command -v go") &&
  test "$path" = "$GOPATH/bin/go"
'

test_expect_success 'g can switch to previous stable Go version' '
  previous_version=$(previous_stable_version) &&
  test -n "$previous_version" &&
  output=$(run_with_g_env "g install $previous_version && go version") &&
  case "$output" in *"go$previous_version"*) true ;; *) false ;; esac
'

test_expect_success 'g can self-upgrade through install script' '
  run_with_g_env "g self-upgrade"
'

test_done
