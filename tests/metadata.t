#!/bin/sh

test_description='Go download metadata tests'

. "${SHARNESS_PATH:-./.tmp/sharness.sh}"

mock_path="$SHARNESS_BUILD_DIRECTORY/mocks"
g_bin="$SHARNESS_BUILD_DIRECTORY/bin/g"
GOPATH="$HOME/go"
GOROOT="$HOME/.go"
export GOPATH GOROOT

run_with_fixture_metadata() {
  env \
    HOME="$HOME" \
    GOPATH="$GOPATH" \
    GOROOT="$GOROOT" \
    MOCK_ARCHIVE="$MOCK_ARCHIVE" \
    REAL_CURL="$(command -v curl)" \
    REAL_WGET="$(command -v wget)" \
    PATH="$mock_path:$GOPATH/bin:$PATH" \
    SHELL=/bin/bash \
    sh -c "$1"
}

test_expect_success 'create mock Go archive' '
  mkdir -p archive/go/bin &&
  printf "#!/bin/sh\nprintf go\n" >archive/go/bin/go &&
  chmod +x archive/go/bin/go &&
  tar -czf go1.22.2.linux-amd64.tar.gz -C archive go &&
  MOCK_ARCHIVE="$PWD/go1.22.2.linux-amd64.tar.gz" &&
  export MOCK_ARCHIVE
'

test_expect_success 'list-all reads stable versions from Go metadata' '
  output=$(run_with_fixture_metadata "$g_bin list-all") &&
  printf "%s\n" "$output" >actual &&
  grep "1.22.1" actual &&
  grep "1.22.2" actual &&
  ! grep "1.23rc1" actual
'

test_expect_success 'list-all --unstable includes unstable metadata versions' '
  output=$(run_with_fixture_metadata "$g_bin list-all --unstable") &&
  printf "%s\n" "$output" >actual &&
  grep "1.23rc1" actual
'

test_expect_success 'download selects archive by version, os, arch, and kind' '
  output=$(run_with_fixture_metadata "$g_bin download 1.22.2 --os linux --arch amd64") &&
  printf "%s\n" "$output" >actual &&
  grep "https://dl.google.com/go/go1.22.2.linux-amd64.tar.gz" actual &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_done
