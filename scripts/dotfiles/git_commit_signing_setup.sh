#! /usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright © 2024 RemasteredArch
#
# This file is part of dotfiles.
#
# Dotfiles is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Dotfiles is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with dotfiles. If not, see <https://www.gnu.org/licenses/>.

# git_commit_signing_setup.sh: A script to create and configure commit signing with Git. Designed for use on Ubuntu 24.04

set -eo pipefail # Quit upon any error
# set -euo pipefail # Quit upon any error or attempt to access unset variables

declare -A script
script[name]="git_commit_signing_setup.sh"
script[version]="v0.1"
script[authors]="RemasteredArch 2024"

set_style() {
  local name="$1"
  local style="$2"

  text[$name]="\e[${style}m"
}

declare -A text
set_style reset 0
set_style bold 1
set_style italic 3
set_style faint 90
set_style white 97
set_style highlight_gray 100

announce() {
  echo -e "\n${text[reset]}${text[white]}${text[highlight_gray]}$*${text[reset]}"
}

help_entry() {
  local short_form="$1"
  local long_form="$2"
  local description="$3"
  local long_form_length=${4:-13}

  local args=$#
  shift $((args < 4 ? args : 4)) # min($#, 4)

  echo "  $short_form ${text[faint]}|${text[reset]} $(printf "%-${long_form_length}s" "$long_form")    ${text[faint]}$description${text[reset]}"

  [ -n "$1" ] || return 0

  local default_prefix="    (Default: "
  echo -n "${text[faint]}$default_prefix'$1'"
  shift

  while [ -n "$1" ]; do
    printf ",\n%${#default_prefix}s%s" ' ' "'$1'"
    shift
  done
  echo ")${text[reset]}"
}

help() {
  echo -e "$(cat << EOF
${text[bold]}${script[name]}${text[reset]} ${text[italic]}${script[version]}${text[reset]}:
  A script to create and configure commit signing with Git. Designed for use on Ubuntu 24.04.

${text[bold]}Usage:${text[reset]}
$(help_entry -h --help "Prints this help message")
$(help_entry -v --version "Prints the version of this script")
$(help_entry -l --local "Disabling checking and setting Git configurations with --global")

License:${text[faint]}
  ${script[name]} is a part of dotfiles.

  Dotfiles is free software: you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation, either version 3 of the License, or (at your option) any later
  version.

  Dotfiles is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  dotfiles. If not, see <https://www.gnu.org/licenses/>.${text[reset]}
EOF
  )"
}

version() {
  echo "${script[version]}"
}

get_parameter() {
  local parameter="$1"
  local default="$2"

  read -rp "Enter $parameter for GPG key (default: $default): " response

  echo "${response:=$default}"

  unset response
}


[ "$1" != "-l" ] && [ "$1" != "--local" ] && git_scope="--global"
[ "$1" = "-h" ] || [ "$1" = "--help" ] && {
  help
  exit 0
}
[ "$1" = "-v" ] || [ "$1" = "--version" ] && {
  version
  exit 0
}


announce "Getting parameters for GPG key"

while true; do
  # shellcheck disable=SC2086
  name=$(get_parameter name "$(git config $git_scope user.name)")
  # shellcheck disable=SC2086
  email=$(get_parameter email "$(git config $git_scope user.email)")
  comment=$(get_parameter comment "Git signing key ($(hostname))")
  duration=$(get_parameter duration "1y")
  user_id="$name ($comment) <$email>"

cat << EOF
About to run:
  gpg --quick-generate-key "$user_id" rsa4096 sign "$duration"

EOF

  read -rp "Is this correct? (y/n) " response
  [ "$response" = "y" ] && break
done


announce "Generating key"

gpg --quick-generate-key "$user_id" rsa4096 sign "$duration"


announce "Fetching key"

gpg_key_id=$( \
  gpg \
    --with-colons \
    --keyid-format=long \
    --list-secret-keys "=$user_id" \
   | grep \
    --only-matching \
    --perl-regexp 'sec:([^:]*:){3}\K[^:]+(?=:)'
)


temp_public_key_file=$(mktemp -t git_public_key.XXXX.pub)
announce "Printing public key for secret key (id: $gpg_key_id) (also outputs to $temp_public_key_file)"

gpg --armor --export "$gpg_key_id" | tee "$temp_public_key_file"
echo "This public key is what your Git host will need to verify your commits"


announce "Enabling commit signing with secret key"

git_config() {
  local config="$1"
  local value="$2"

  local command="git config $git_scope $config $value"
  echo "- $command"
  eval "$command"
}

echo "Running..."
git_config gpg.format openpgp
git_config user.signingkey "$gpg_key_id"
git_config commit.gpgsign true
