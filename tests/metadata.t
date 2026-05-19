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
    MOCK_URL_LOG="${MOCK_URL_LOG:-}" \
    REAL_CURL="$(command -v curl)" \
    REAL_WGET="$(command -v wget)" \
    PATH="$mock_path:$GOPATH/bin:$PATH" \
    SHELL=/bin/bash \
    sh -c "$1"
}

test_expect_success 'create mock Go archive' '
  mkdir -p archive/go/bin &&
  {
    echo "#!/bin/sh" &&
    echo "echo go"
  } >archive/go/bin/go &&
  chmod +x archive/go/bin/go &&
  tar -czf go1.22.2.linux-amd64.tar.gz -C archive go &&
  MOCK_ARCHIVE="$PWD/go1.22.2.linux-amd64.tar.gz" &&
  export MOCK_ARCHIVE
'

test_expect_success 'list-all reads stable versions from Go metadata' '
  output=$(run_with_fixture_metadata "$g_bin list-all") &&
  echo "$output" >actual &&
  grep "1.22.1" actual &&
  grep "1.22.2" actual &&
  ! grep "1.23rc1" actual
'

test_expect_success 'list-all --unstable includes unstable metadata versions' '
  output=$(run_with_fixture_metadata "$g_bin list-all --unstable") &&
  echo "$output" >actual &&
  grep "1.23rc1" actual
'

test_expect_success 'download selects archive by version, os, arch, and kind' '
  MOCK_URL_LOG="$PWD/default-url.log" &&
  export MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "$g_bin download 1.22.2 --os linux --arch amd64") &&
  echo "$output" >actual &&
  grep "https://dl.google.com/go/go1.22.2.linux-amd64.tar.gz" actual &&
  grep "https://go.dev/dl/?mode=json&include=all" default-url.log &&
  grep "https://dl.google.com/go/go1.22.2.linux-amd64.tar.gz" default-url.log &&
  unset MOCK_URL_LOG &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_expect_success 'archive mirror env override normalizes trailing slash' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  MOCK_URL_LOG="$PWD/mirror-url.log" &&
  export MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "G_GO_ARCHIVE_URL=https://mirror.example/go/ $g_bin download 1.22.2 --os linux --arch amd64") &&
  echo "$output" >actual &&
  grep "https://mirror.example/go/go1.22.2.linux-amd64.tar.gz" actual &&
  grep "https://go.dev/dl/?mode=json&include=all" mirror-url.log &&
  grep "https://mirror.example/go/go1.22.2.linux-amd64.tar.gz" mirror-url.log &&
  ! grep "https://mirror.example/go//" mirror-url.log &&
  unset MOCK_URL_LOG &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_expect_success 'archive URL command argument takes precedence over env var' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  MOCK_URL_LOG="$PWD/cli-url.log" &&
  export MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "G_GO_ARCHIVE_URL=https://invalid.example/go $g_bin download 1.22.2 --archive-url https://mirror.example/go --os linux --arch amd64") &&
  echo "$output" >actual &&
  grep "https://mirror.example/go/go1.22.2.linux-amd64.tar.gz" actual &&
  grep "https://go.dev/dl/?mode=json&include=all" cli-url.log &&
  grep "https://mirror.example/go/go1.22.2.linux-amd64.tar.gz" cli-url.log &&
  unset MOCK_URL_LOG &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_done
