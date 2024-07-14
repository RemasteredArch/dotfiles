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

# clock.sh: prints a simple clock centered on the screen use with watch(1):
# watch --no-title --interval 1 ./clock.sh

get_clock() {
  date +%H:%M.%S | toilet --font future
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

center_and_justify_text "$(get_clock)"
