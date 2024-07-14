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

# clock.sh: prints a simple clock centered on the screen with watch(1)

set -eo pipefail # Quit upon any error or attempt to access unset variables

has() {
  [ "$(type "$1" 2> /dev/null)" ]
}

get_formatter() {
  has toilet && {
    echo "toilet"
    return
  }
  has figlet && {
    echo "figlet"
    return
  }

  echo "figlet or toilet not detected! Please install one." >&2
  exit 1
}

get_clock() {
  local formatter="$1" # "toilet" or "figlet"

  date +%H:%M.%S | "$formatter" --font future
}

# Assumes that all lines will be of the same length
center_and_justify_text() {
  local text="$1"
  readarray -t as_array < <(echo "$text")

  declare -i cols
  declare -i rows
  cols=$(tput cols)
  rows=$(tput lines)

  local line_length="${#as_array[0]}"
  local horizontal_padding=$(((cols - line_length) / 2))

  local line_count=${#as_array[@]}
  local vertical_padding=$(((rows - line_count) / 2))

  for ((i = 0; i < vertical_padding; i++)); do
    echo
  done
  for i in "${as_array[@]}"; do
    printf "%${horizontal_padding}s%s\n" " " "$i"
  done

  unset as_array cols rows
}

formatter=$(get_formatter)

if [ "$1" = "-n" ] || [ "$1" = "--no-repeat" ]; then
  center_and_justify_text "$(get_clock "$formatter")"
else
  export formatter
  export -f center_and_justify_text get_clock

  watch --no-title --interval 1 --exec bash -c "center_and_justify_text \"\$(get_clock \"$formatter\")\""
fi
