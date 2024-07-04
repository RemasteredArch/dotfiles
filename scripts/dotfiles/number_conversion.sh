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

# number_conversion.sh: provides a number of simple utilities for binary, decimal, and hexadecimal conversions

# converts a number from a given base (radix) to another base
# this is also a good fallback when the derivative functions run into the printf size limit
# usage: convert_number <input base> <output base> <number>
# For example:
# - `convert_number 2 10 1111` returns `15`
# - `convert_number 16 10 f` returns `15`
convert_number() {
  local input_base="$1"
  local output_base="$2"
  local input_number="${3^^}"
  printf "obase=%d; ibase=%d; %s\n" "$output_base" "$input_base" "$input_number" | bc
}
export -f convert_number

# converts a decimal number to binary
# usage: binary <decimal> <length of binary output>
# length defaults to 8
# For example:
# - `binary 10 4` returns `1010`
# - `binary 10` returns `00001010`
binary() {
  local input_decimal="$1"
  local length=${2:-8}
  printf "%0${length}d\n" "$(convert_number 10 2 "$input_decimal")"
}
export -f binary

# converts a binary number to decimal
# usage: decimal <binary>
# length defaults to 8
# For example:
# - `binary 1010` returns `10`
decimal() {
  local input_binary="$1"
  convert_number 2 10 "$input_binary"
}
export -f decimal

# converts a hex number to binary
# usage: hex2b <hex> <length of binary output>
# length defaults to 16
# For example:
# - `hex2b ff 8` returns `11111111`
# - `hex2b ffff` returns `1111111111111111`
hex2b() {
  local input_hex="$1"
  local length=${2:-16}
  printf "%0${length}d\n" "$(convert_number 16 2 "$input_hex")"
}
export -f hex2b

# converts a hex number to decimal
# usage: hex2d <hex>
# For example:
# - `hex2d ffff` returns `65535`
hex2d() {
  local input_hex="$1"
  convert_number 16 10 "$input_hex"
}
export -f hex2d

# converts a decimal number to hex
# usage: hex <decimal>
# For example:
# - `hex 65535` returns `ffff`
hex() {
  local input_decimal=$1
  convert_number 10 16 "$input_decimal"
}
export -f hex
