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
    ENV="${ENV:-}" \
    G_SHELLS_FILE="${G_SHELLS_FILE:-$PWD/missing-shells}" \
    MOCK_BASH_ALIAS_OUTPUT="${MOCK_BASH_ALIAS_OUTPUT:-}" \
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

test_expect_success 'installer rejects unsupported shell selection' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  if run_install "/unknown/shell" powershell >unsupported-output 2>&1; then
    false
  fi &&
  grep "unknown argument or shell \"powershell\"" unsupported-output
'

test_expect_success 'installer explains ash ENV requirement' '
  rm -rf "$GOPATH" "$GOROOT" "$HOME/.profile" &&
  create_existing_g &&
  if run_install "/unknown/shell" ash >ash-missing-env-output 2>&1; then
    false
  fi &&
  grep "ash requires the \$ENV var" ash-missing-env-output &&
  grep "ENV=\$HOME/.profile g-install ash" ash-missing-env-output
'

test_expect_success 'installer configures ash when ENV exists' '
  rm -rf "$GOPATH" "$GOROOT" "$HOME/.profile" &&
  create_existing_g &&
  touch "$HOME/.profile" &&
  ENV="$HOME/.profile" &&
  export ENV &&
  run_install "/unknown/shell" ash >ash-output 2>&1 &&
  grep "configuring ash in $HOME/.profile" ash-output &&
  grep "g-install" "$HOME/.profile" &&
  unset ENV
'

test_expect_success 'installer does not configure duplicate selected shells' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  {
    echo "$(command -v bash)" &&
    echo "$(command -v bash)"
  } >shells &&
  G_SHELLS_FILE="$PWD/shells" &&
  export G_SHELLS_FILE &&
  run_install "$(command -v bash)" "bash bash" >duplicate-output 2>&1 &&
  test "$(grep -c "configuring bash" duplicate-output)" = 1 &&
  unset G_SHELLS_FILE
'

test_expect_success 'installer rerun does not duplicate config line' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  run_install "$(command -v bash)" >first-output 2>&1 &&
  run_install "$(command -v bash)" >second-output 2>&1 &&
  grep "skipping bash because g has been configured already" second-output &&
  test "$(grep -c "g-install" "$(bash_dotfile)")" = 1
'

test_expect_success 'installer sets fallback alias when g alias already exists' '
  rm -rf "$GOPATH" "$GOROOT" "$(bash_dotfile)" &&
  create_existing_g &&
  MOCK_BASH_ALIAS_OUTPUT="alias g=\"git\"" &&
  export MOCK_BASH_ALIAS_OUTPUT &&
  run_install "$(command -v bash)" >alias-output 2>&1 &&
  grep "alias ggovm=\"\$GOPATH/bin/g\"" "$(bash_dotfile)" &&
  unset MOCK_BASH_ALIAS_OUTPUT
'

test_done
