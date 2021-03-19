#!/bin/sh

# MIT License
#
# Copyright (c) 2018 Stefan Maric
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# POSIX shell doesn't support errtrace nor pipefail.

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR.
set -o nounset

# Uncomment these if you are debugging.
# set -o xtrace
# set -o verbose

#
# Exit with the given error <msg ...>.
#

error_and_abort() {
  printf '\n  %s: %s\n\n' "ERROR" "$*" >&2
  exit 1
}

#
# Log formated info as <type>: <msg>.
#

log_info() {
  printf '%14s: %s\n' "$1" "$2"
}

#
# Pre-check environment variables.
#

GOPATH=${GOPATH:-$HOME/go}
GOROOT=${GOROOT:-$HOME/.go}

if [ "$(echo "$GOPATH" | cut -c1)" != "/" ]; then
  error_and_abort "\$GOPATH must be an absolute path but it is set to $GOPATH"
fi

if [ "$(echo "$GOROOT" | cut -c1)" != "/" ]; then
  error_and_abort "\$GOROOT must be an absolute path but it is set to $GOROOT"
fi

IS_UPGRADING=false
CURRENT_VERSION=

if [ -x "$GOPATH/bin/g" ] && command "$GOPATH/bin/g" --version > /dev/null 2>&1; then
  IS_UPGRADING=true
  CURRENT_VERSION=$(command "$GOPATH/bin/g" --version)
fi

HAS_GO_ALREADY=false
GO_LOCATION=

if command -v go > /dev/null; then
  HAS_GO_ALREADY=true
  GO_LOCATION=$(command -v go)
fi

NON_INTERACTIVE=false

G_DOWNLOAD_URL="https://git.io/g-bin"

COMMENT_MESSAGE="g-install: do NOT edit, see https://github.com/stefanmaric/g"

USER_SHELL=

if [ -n "${SHELL:-}" ]; then
  USER_SHELL=$(basename "$SHELL")
fi

SUPPORTED_SHELLS="ash dash bash csh tsch zsh fish"
INSTALLED_SHELLS=""
SELECTED_SHELLS=""

G_ALIAS="g"
G_ALIAS_CHANGED=false
G_ALIAS_USED_IN_SHELL=""

#
# POSIX utils.
#

# Read one char at the time up-to some limit: <var_name> [<read_limit> = 1]
# Extracted from: https://unix.stackexchange.com/a/464963
read_user_input() {
  file_option=
  input_device=
  var_name=$1
  read_limit=${2:-1}

  # Determine where to read user input from.
  if [ -f "${0:-}" ]; then
    # When running the script as a binary file, use stdin.
    input_device="/dev/stdin"
  else
    # When running in a pipe, read from the tty.
    input_device="/dev/tty"
  fi

  if stty -F "$input_device" > /dev/null 2>&1; then
    file_option="-F"
  else
    file_option="-f"
  fi

  # Take a backup of the previous settings beforehand.
  saved_tty_settings=$(stty "$file_option" "$input_device" -g)
  # Ensure the device is out of icanon, set min and time to sane value, but
  # don't otherwise touch other input or local settings (echo, isig, icrnl...).
  stty "$file_option" "$input_device" -icanon min 1 time 0

  # Reset target variable in case it was in use before.
  eval "$var_name="

  while
    # Read one byte, using a work around for the fact that command substitution
    # strips the last character.
    c=$(
      dd if=$input_device bs=1 count=1 2> /dev/null
      echo .
    )
    c=${c%.}

    # Break out of the loop on empty input (EOF) or if a full character has been
    # accumulated in the output variable (using "wc -m" to count the number of
    # characters).
    test -n "$c" && eval "
      $var_name=\"\${${var_name}}\$c\"
      [ \"\$(printf '%s' \"\$$var_name\" | wc -m)\" -lt $read_limit ]
    "
  do
    continue
  done

  # Restore settings saved earlier.
  stty "$file_option" "$input_device" "$saved_tty_settings"
}

pretty_print_path() {
  printf '%s' "$1" | sed "s|${HOME}|\$HOME|g"
}

#
# Check if the given <string> is present in the given <list>.
#

list_includes() {
  # First argument is search element.
  search_element=$1
  # The rest is the array to lookup.
  shift

  found=1

  for item in "$@"; do
    if [ "$item" = "$search_element" ]; then
      found=0
      break
    fi
  done

  return $found
}

#
# Download file with cUrl or fallback to wget.
#

download() {
  if command -v curl > /dev/null; then
    params="--location --silent --show-error"

    # shellcheck disable=SC2086
    curl $params "$@"
  elif command -v wget > /dev/null; then
    params="--quiet -O-"

    # shellcheck disable=SC2086
    wget $params "$@"
  else
    error_and_abort "curl or wget required"
  fi
}

#
# Find the proper init file for a given <shell>.
#

get_dotfile_for_shell() {
  case "$1" in
    bash)
      if [ "$(uname | tr '[:upper:]' '[:lower:]')" = "darwin" ]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    zsh) echo "$HOME/.zshrc" ;;
    csh) echo "$HOME/.cshrc" ;;
    tcsh) echo "$HOME/.tcshrc" ;;
    ash | dash)
      if [ -z "${ENV:-}" ] || [ ! -f "$ENV" ]; then
        error_and_abort "for ash and dash, the \$ENV var must be properly configured"
      else
        echo "$ENV"
      fi
      ;;
  esac
}

#
# Get line that properly sets GOROOT, GOPATH, and PATH for a given <shell>.
#

get_line_for_shell() {
  case "$1" in
    ash | dash | bash | zsh | csh | tcsh)
      printf '\n%s %s %s %s' \
        "export GOPATH=\"$(pretty_print_path "$GOPATH")\";" \
        "export GOROOT=\"$(pretty_print_path "$GOROOT")\";" \
        "export PATH=\"\$GOPATH/bin:\$PATH\";" \
        "# $COMMENT_MESSAGE"
      ;;
    fish)
      printf '\n%s %s %s %s' \
        "set -gx GOPATH $(pretty_print_path "$GOPATH");" \
        "set -gx GOROOT $(pretty_print_path "$GOROOT");" \
        "set -gx PATH \$GOPATH/bin \$PATH;" \
        "# $COMMENT_MESSAGE"
      ;;
  esac
}

#
# Download g, put it in the right place, and give it execution rights.
#

install_g() {
  log_info "info" "creating dir $GOPATH/bin"
  mkdir -p "$GOPATH/bin"
  log_info "info" "copying g in $GOPATH/bin/g"
  download "$G_DOWNLOAD_URL" > "$GOPATH/bin/g"
  log_info "info" "setting permissions"
  chmod +x "$GOPATH/bin/g"
}

#
# Check whether 'g' alias is already used, setup alternatives alias if it is
#

configure_g_alias() {
  if ! g_alias_defined "$G_ALIAS"; then
    return 0
  fi

  G_ALIAS_CHANGED=true

  if [ "$NON_INTERACTIVE" = true ]; then
    G_ALIAS="ggovm"
    return 0
  fi

  while g_alias_defined "$G_ALIAS"; do
    if ! prompt_set_alias "$G_ALIAS" "$G_ALIAS_USED_IN_SHELL"; then
      echo
      echo
      log_info "info" "skipping setup alias for g"
      G_ALIAS_CHANGED=false
      break
    fi

    G_ALIAS=$(set_alias_name)
  done
}

#
# Iteratively check every selected shells for defined alias
#

g_alias_defined() {
  alias_already_used=false

  for shell in $SELECTED_SHELLS; do
    if exists "$shell" "$1"; then
      alias_already_used=true
      G_ALIAS_USED_IN_SHELL="$shell"
    fi
  done

  if [ "$alias_already_used" = true ]; then
    return 0
  fi

  return 1
}

#
# Check whether command already exists
#

exists() {
  case "$1" in
    zsh)
      zsh -ci alias | grep "$2=" > /dev/null
      ;;
    bash)
      bash -ci alias | grep "$2=" > /dev/null
      ;;
    fish)
      fish -c 'alias' | grep " $2 " > /dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

#
# Prompt user whether they want to set a new alias
#

prompt_set_alias() {
  echo
  printf 'Alias "%s" is already defined in "%s", set another alias? [y/N] ' "$1" "$2"
  yes_alias=
  read_user_input yes_alias

  case $yes_alias in
    [Yy]*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

#
# Prompt user for new alias name
#

set_alias_name() {
  input_device=
  # Determine where to read user input from.
  if [ -f "${0:-}" ]; then
    # When running the script as a binary file, use stdin.
    input_device="/dev/stdin"
  else
    # When running in a pipe, read from the tty.
    input_device="/dev/tty"
  fi

  alias_name=
  echo >&2
  printf "Enter alias name! [ggovm] " >&2
  read -r alias_name < $input_device
  echo >&2
  if [ -z "$alias_name" ]; then
    echo "ggovm"
  else
    echo "$alias_name"
  fi
}

#
# Set environment variables in all selected shells.
#

configure_selected_shells() {
  for shell in $SELECTED_SHELLS; do
    # First check the dotfile is actually known, then use it.
    get_dotfile_for_shell "$shell" > /dev/null
    dotfile_path=$(get_dotfile_for_shell "$shell")
    config_line=$(get_line_for_shell "$shell")

    if test -f "$dotfile_path" && grep "g-install" "$dotfile_path" > /dev/null; then
      log_info "info" "skipping $shell because g has been configured already in $dotfile_path"
    else
      log_info "info" "configuring $shell in $dotfile_path"
      echo "$config_line" >> "$dotfile_path"
      set_g_alias "$dotfile_path"
    fi
  done
}

#
# set alias in dotfile
#

set_g_alias() {
  if [ "$G_ALIAS_CHANGED" = true ]; then
    alias_line="alias $G_ALIAS=\"\$GOPATH/bin/g\"; # $COMMENT_MESSAGE"
    echo "$alias_line" >> "$1"
  fi
}

#
# Start the installation process.
#

initiate() {
  yes_g=
  yes_go=

  if [ "${#SELECTED_SHELLS}" -eq 0 ]; then
    error_and_abort "no shell has been selected for installation"
  fi

  echo

  if [ "$IS_UPGRADING" = true ]; then
    echo "You are about to upgrade g, the gluten-free go version manager at:"
  else
    echo "You are about to install g, the gluten-free go version manager at:"
  fi

  echo
  echo "    $GOPATH/bin/g"
  echo

  if [ "$IS_UPGRADING" = false ]; then
    echo "The following environment variables:"
    echo
    log_info "\$GOROOT" "$GOROOT"
    log_info "\$GOPATH" "$GOPATH"
    log_info "\$PATH" "$GOPATH/bin"
    echo
    echo "    are going to be set in:"
    echo
    for shell in $SELECTED_SHELLS; do
      # First check the dotfile is actually known, then use it.
      get_dotfile_for_shell "$shell" > /dev/null
      log_info "$shell" "$(get_dotfile_for_shell "$shell")"
    done
    echo

    if [ "$HAS_GO_ALREADY" = true ]; then
      echo "warning: it appears you have a go installation already at: ${GO_LOCATION}"
      echo
      echo "    g can still be used alongside and the go versions managed by g will take"
      echo "    precedence over your current go installation, only for the current user ($USER)."
      echo "    For more details, see: https://github.com/stefanmaric/g"
      echo
    fi

    if [ "$GOPATH" != "$HOME/go" ]; then
      echo "warning: using a non-default \$GOPATH: $(pretty_print_path "$GOPATH")"
    fi
    if [ "$GOROOT" != "$HOME/.go" ]; then
      echo "warning: using a non-default \$GOROOT: $(pretty_print_path "$GOROOT")"
    fi
    if [ "$GOPATH" != "$HOME/go" ] || [ "$GOROOT" != "$HOME/.go" ]; then
      echo
      echo "    This usually presents no problem, but be sure it is intended."
      echo
    fi
  fi

  if [ "$NON_INTERACTIVE" = false ]; then
    printf "Do you want to continue? [y/N] "
    read_user_input yes_g

    echo

    if [ "$yes_g" != "y" ]; then
      echo "Aborted"
      exit 1
    fi
  fi

  echo

  install_g
  configure_g_alias
  configure_selected_shells

  echo

  if [ "$IS_UPGRADING" = true ]; then
    new_version=$(command "$GOPATH/bin/g" --version)

    if [ "$CURRENT_VERSION" = "$new_version" ]; then
      echo "g is already up-to-date"
    else
      echo "g has been successfully upgraded from $CURRENT_VERSION to $new_version"
    fi
  else
    echo "g has been successfully installed"
    echo "NOTE: restart your shell sessions before using g or go"
    echo "For more information, see: https://github.com/stefanmaric/g"
    echo

    if [ "$NON_INTERACTIVE" = false ]; then
      printf "Do you want to install the latest go version? [y/N] "
      read_user_input yes_go

      echo

      if [ "$yes_go" != "y" ]; then
        exit 0
      fi
    fi

    echo

    export GOROOT
    export GOPATH
    export PATH="$GOPATH/bin:$PATH"
    exec "$GOPATH/bin/g" install latest
  fi
}

#
# Collect installed shells we support and pre-select user's login shell.
#

while IFS= read -r shell_path; do
  if [ "$(echo "$shell_path" | cut -c1)" != "/" ]; then
    continue
  fi

  shell_name=$(basename "$shell_path")

  # Collect only supported shells.
  # shellcheck disable=SC2086
  if list_includes "$shell_name" $SUPPORTED_SHELLS; then
    INSTALLED_SHELLS="$INSTALLED_SHELLS $shell_name"

    # Select user's shell for configuration by default.
    if [ "$shell_name" = "$USER_SHELL" ]; then
      SELECTED_SHELLS="$SELECTED_SHELLS $shell_name"
    fi
  fi
  # This file lists abs paths for installed shells. This at-bottom syntax is to
  # prevent subshells and allow for the loop code to modify global variables.
  # See: https://stackoverflow.com/questions/16854280/
done < /etc/shells

# This script is useless if it doesn't support any of user's installed shells.
if [ "${#INSTALLED_SHELLS}" -eq 0 ]; then
  error_and_abort "none of the supported shells seems installed, see: https://github.com/stefanmaric/g#manually"
fi

#
# Handle arguments.
#

while test $# -ne 0; do
  case "$1" in
    -y | --non-interactive) NON_INTERACTIVE=true ;;
    *)
      # shellcheck disable=SC2086
      if list_includes "$1" $INSTALLED_SHELLS; then
        # shellcheck disable=SC2086
        if ! list_includes "$1" $SELECTED_SHELLS; then
          SELECTED_SHELLS="$SELECTED_SHELLS $1"
        fi
      elif list_includes "$1" $SUPPORTED_SHELLS; then
        error_and_abort "$1 has been selected but is not installed"
      else
        error_and_abort "unknown argument or shell \"$1\""
      fi
      ;;
  esac
  shift
done

initiate
