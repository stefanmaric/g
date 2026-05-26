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
    MOCK_ARCHIVE_SHA256="${MOCK_ARCHIVE_SHA256:-}" \
    MOCK_FILE_OUTPUT="${MOCK_FILE_OUTPUT:-}" \
    MOCK_URL_LOG="${MOCK_URL_LOG:-}" \
    REAL_CURL="$(command -v curl)" \
    REAL_FILE="$(command -v file)" \
    REAL_WGET="$(command -v wget)" \
    PATH="$mock_path:$GOPATH/bin:$PATH" \
    SHELL=/bin/bash \
    sh -c "$1"
}

run_with_path() {
  env \
    HOME="$HOME" \
    GOPATH="$GOPATH" \
    GOROOT="$GOROOT" \
    PATH="$1" \
    SHELL=/bin/bash \
    sh -c "$2"
}

sha256_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    openssl dgst -sha256 "$1" | sed 's/^.*= //'
  fi
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
  MOCK_ARCHIVE_SHA256=$(sha256_file "$MOCK_ARCHIVE") &&
  export MOCK_ARCHIVE MOCK_ARCHIVE_SHA256
'

test_expect_success 'g accepts exact GOPATH bin PATH entry' '
  output=$(run_with_path "$GOPATH/bin:$mock_path:/bin:/usr/bin" "$g_bin --version") &&
  echo "$output" | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$"
'

test_expect_success 'g rejects substring-only GOPATH bin PATH entry' '
  if run_with_path "$GOPATH/bin-old:$mock_path:/bin:/usr/bin" "$g_bin --version" >actual 2>&1; then
    false
  fi &&
  grep "\$GOPATH/bin not found in \$PATH" actual
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

test_expect_success 'remote listing aliases read Go metadata' '
  output=$(run_with_fixture_metadata "$g_bin ls-remote") &&
  echo "$output" >actual &&
  grep "1.22.2" actual &&
  output=$(run_with_fixture_metadata "$g_bin list-remote") &&
  echo "$output" >actual &&
  grep "1.22.2" actual
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

test_expect_success 'fetch alias downloads archive' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  output=$(run_with_fixture_metadata "$g_bin fetch 1.22.2 --os linux --arch amd64") &&
  echo "$output" >actual &&
  grep "downloaded: 1.22.2" actual &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_expect_success 'download rejects archive with checksum mismatch' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  bad_sha256=0000000000000000000000000000000000000000000000000000000000000000 &&
  if run_with_fixture_metadata "MOCK_ARCHIVE_SHA256=$bad_sha256 $g_bin download 1.22.2 --os linux --arch amd64" >actual 2>&1; then
    false
  fi &&
  grep "checksum mismatch" actual &&
  ! test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_expect_success 'download reports unavailable operating system from metadata' '
  if run_with_fixture_metadata "$g_bin download 1.22.2 --os solaris --arch amd64" >actual 2>&1; then
    false
  fi &&
  grep "no Go archive found for version 1.22.2 on solaris/amd64" actual
'

test_expect_success 'download reports unavailable architecture from metadata' '
  if run_with_fixture_metadata "$g_bin download 1.22.2 --os linux --arch mips" >actual 2>&1; then
    false
  fi &&
  grep "no Go archive found for version 1.22.2 on linux/mips" actual
'

test_expect_success 'install with matching arch override reuses existing version' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  mkdir -p "$GOROOT/.versions/1.22.2/bin" &&
  {
    echo "#!/bin/sh" &&
    echo "echo go version go1.22.2 existing"
  } >"$GOROOT/.versions/1.22.2/bin/go" &&
  chmod +x "$GOROOT/.versions/1.22.2/bin/go" &&
  MOCK_FILE_OUTPUT="ELF 64-bit LSB executable, x86-64" &&
  MOCK_URL_LOG="$PWD/reuse-url.log" &&
  export MOCK_FILE_OUTPUT MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "$g_bin install 1.22.2 --os linux --arch amd64 && go version") &&
  echo "$output" >actual &&
  grep "go version go1.22.2 existing" actual &&
  { test ! -e reuse-url.log || ! grep "go.dev" reuse-url.log; } &&
  unset MOCK_FILE_OUTPUT MOCK_URL_LOG
'

test_expect_success 'use alias installs and switches version' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  output=$(run_with_fixture_metadata "$g_bin use 1.22.2 --os linux --arch amd64 && go version") &&
  echo "$output" >actual &&
  grep "installed: go" actual &&
  grep "go" actual &&
  test -x "$GOROOT/.versions/1.22.2/bin/go"
'

test_expect_success 'set reports incomplete installation with recovery guidance' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  mkdir -p "$GOROOT/.versions/1.22.2" &&
  touch "$GOROOT/.versions/1.22.2/g.lock" &&
  if run_with_fixture_metadata "$g_bin set 1.22.2" >actual 2>&1; then
    false
  fi &&
  grep "version 1.22.2 installation is incomplete" actual &&
  grep "g remove 1.22.2" actual
'

test_expect_success 'install with mismatched arch override replaces existing version' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  mkdir -p "$GOROOT/.versions/1.22.2/bin" &&
  {
    echo "#!/bin/sh" &&
    echo "echo old"
  } >"$GOROOT/.versions/1.22.2/bin/go" &&
  chmod +x "$GOROOT/.versions/1.22.2/bin/go" &&
  MOCK_FILE_OUTPUT="ELF 64-bit LSB executable, x86-64" &&
  MOCK_URL_LOG="$PWD/replace-url.log" &&
  export MOCK_FILE_OUTPUT MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "$g_bin install 1.22.2 --os linux --arch arm64") &&
  echo "$output" >actual &&
  grep "replacing" actual &&
  grep "https://dl.google.com/go/go1.22.2.linux-arm64.tar.gz" replace-url.log &&
  test -x "$GOROOT/.versions/1.22.2/bin/go" &&
  unset MOCK_FILE_OUTPUT MOCK_URL_LOG
'

test_expect_success 'install with unknown installed arch replaces existing version' '
  rm -rf "$GOROOT/.versions/1.22.2" &&
  mkdir -p "$GOROOT/.versions/1.22.2/bin" &&
  {
    echo "#!/bin/sh" &&
    echo "echo old"
  } >"$GOROOT/.versions/1.22.2/bin/go" &&
  chmod +x "$GOROOT/.versions/1.22.2/bin/go" &&
  MOCK_FILE_OUTPUT="POSIX shell script text executable" &&
  MOCK_URL_LOG="$PWD/unknown-url.log" &&
  export MOCK_FILE_OUTPUT MOCK_URL_LOG &&
  output=$(run_with_fixture_metadata "$g_bin install 1.22.2 --os linux --arch amd64") &&
  echo "$output" >actual &&
  grep "replacing" actual &&
  grep "https://dl.google.com/go/go1.22.2.linux-amd64.tar.gz" unknown-url.log &&
  test -x "$GOROOT/.versions/1.22.2/bin/go" &&
  unset MOCK_FILE_OUTPUT MOCK_URL_LOG
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

test_expect_success 'installed version aliases work' '
  output=$(run_with_fixture_metadata "$g_bin ls") &&
  echo "$output" >actual &&
  grep "1.22.2" actual &&
  output=$(run_with_fixture_metadata "$g_bin exec 1.22.2 version") &&
  echo "$output" >actual &&
  grep "go" actual &&
  run_with_fixture_metadata "$g_bin rm 1.22.2" &&
  ! test -d "$GOROOT/.versions/1.22.2" &&
  run_with_fixture_metadata "$g_bin use 1.22.2 --os linux --arch amd64" &&
  test -d "$GOROOT/.versions/1.22.2" &&
  run_with_fixture_metadata "$g_bin uninstall 1.22.2" &&
  ! test -d "$GOROOT/.versions/1.22.2"
'

test_expect_success 'self-update alias runs self-upgrade' '
  if run_with_fixture_metadata "$g_bin self-update" >actual 2>&1; then
    false
  fi &&
  grep "self-upgrade command" actual
'

test_done
