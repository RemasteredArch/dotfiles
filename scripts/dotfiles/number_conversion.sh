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

number_conversions_help() {
    [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]
}

convert_number() {
    number_conversions_help "$1" && cat << EOF
Converts a number from a given base (radix) to another base
  This is also a good fallback when the derivative functions run into the printf size limit

Usage: convert_number <input base> <output base> <number>
For example:
  - 'convert_number 2 10 1111' returns '15'
  - 'convert_number 16 10 f' returns '15'
EOF
    local input_base="$1"
    local output_base="$2"
    local input_number="${3^^}"
    printf "obase=%d; ibase=%d; %s\n" "$output_base" "$input_base" "$input_number" | bc
}
export -f convert_number

binary() {
    number_conversions_help "$1" && cat << EOF
Converts a decimal number to binary

Usage: binary <decimal> <length of binary output>
  Length defaults to 8
For example:
  - 'binary 10 4' returns '1010'
  - 'binary 10' returns '00001010'
EOF
    local input_decimal="$1"
    local length=${2:-8}
    printf "%0${length}d\n" "$(convert_number 10 2 "$input_decimal")"
}
export -f binary

decimal() {
    number_conversions_help "$1" && cat << EOF
Converts a binary number to decimal

Usage: decimal <binary>
  Length defaults to 8
For example:
- 'binary 1010' returns '10'
EOF
    local input_binary="$1"
    convert_number 2 10 "$input_binary"
}
export -f decimal

hex2b() {
    number_conversions_help "$1" && cat << EOF
Converts a hex number to binary

Usage: hex2b <hex> <length of binary output>
  Length defaults to 16
For example:
- 'hex2b ff 8' returns '11111111'
- 'hex2b ffff' returns '1111111111111111'
EOF
    local input_hex="$1"
    local length=${2:-16}
    printf "%0${length}d\n" "$(convert_number 16 2 "$input_hex")"
}
export -f hex2b

hex2d() {
    number_conversions_help "$1" && cat << EOF
Converts a hex number to decimal

Usage: hex2d <hex>
For example:
- 'hex2d ffff' returns '65535'
EOF
    local input_hex="$1"
    convert_number 16 10 "$input_hex"
}
export -f hex2d

hex() {
    number_conversions_help "$1" && cat << EOF
Converts a decimal number to hex

Usage: hex <decimal>
For example:
- 'hex 65535' returns 'ffff'
EOF
    local input_decimal=$1
    convert_number 10 16 "$input_decimal"
}
export -f hex
