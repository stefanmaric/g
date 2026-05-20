#!/bin/sh

test_description='g installer tests'

. "${SHARNESS_PATH:-./.tmp/sharness.sh}"

mock_path="$SHARNESS_BUILD_DIRECTORY/mocks"
install_bin="$SHARNESS_BUILD_DIRECTORY/bin/install"
real_curl=$(command -v curl)
real_wget=$(command -v wget)
GOPATH="$HOME/go"
GOROOT="$HOME/.go"
export GOPATH GOROOT

run_install() {
  env \
    HOME="$HOME" \
    GOPATH="$GOPATH" \
    GOROOT="$GOROOT" \
    G_SHELLS_FILE="$PWD/missing-shells" \
    REAL_CURL="$real_curl" \
    REAL_WGET="$real_wget" \
    PATH="$mock_path:$GOPATH/bin:/bin:/usr/bin" \
    SHELL="$1" \
    sh "$install_bin" -y ${2:-}
}

create_existing_g() {
  mkdir -p "$GOPATH/bin" &&
  {
    echo "#!/bin/sh" &&
    echo "echo 0.0.0"
  } >"$GOPATH/bin/g" &&
  chmod +x "$GOPATH/bin/g"
}

bash_dotfile() {
  if [ "$(uname | tr '[:upper:]' '[:lower:]')" = "darwin" ]; then
    echo "$HOME/.bash_profile"
  else
    echo "$HOME/.bashrc"
  fi
}

test_expect_success 'installer falls back to SHELL when shells file is missing' '
  create_existing_g &&
  run_install "$(command -v bash)" >shell-output 2>&1 &&
  grep "g has been successfully upgraded" shell-output &&
  grep "g-install" "$(bash_dotfile)"
'

test_expect_success 'installer accepts explicit available shell when shells file is missing' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  run_install "/unknown/shell" bash >explicit-output 2>&1 &&
  grep "g has been successfully upgraded" explicit-output &&
  grep "g-install" "$(bash_dotfile)"
'

test_expect_success 'installer rejects unavailable shell when shells file is missing' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  if run_install "/unknown/shell" fish >unavailable-output 2>&1; then
    false
  fi &&
  grep "fish has been selected but is not installed" unavailable-output
'

test_done
