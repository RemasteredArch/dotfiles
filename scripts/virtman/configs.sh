#! /bin/env bash

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

# configs.sh: a basic config selection script using dasel and a toml config file
# will probably be integrated directly into virtman.sh in the future

echo "Existing VM configurations:"

config_file="default.toml"
readarray -t configs < <(dasel --file="$config_file" --read="toml" --write="-" --selector='.virtual_machines.all().name')

for i in "${configs[@]}"; do
  echo "- $i"
done

while [ "$found" = "" ]; do
  echo
  read -rp "Select a configuration: " config

  [ "$config" = "" ] && {
    echo "No config selected!"
    continue
  }

  found=""
  for i in "${configs[@]}"; do
    [ "$config" = "$i" ] && {
      found="$i"
      break 2
    }
  done

  echo "VM '$config' not found!"
done

echo -e "\nSelected virtual machine '$config':"
readarray -t configs < <(dasel --file="$config_file" --read="toml" --selector=".virtual_machines.all().filter(equal(name,$config))")

for i in "${configs[@]}"; do
  echo "- $i"
done
echo

while true; do
  read -rp "Selector: ." selector 
  printf "%s\n" "${configs[@]}" | dasel --read="toml" --write="-" --selector=".$selector"
  echo
done

exit 0
