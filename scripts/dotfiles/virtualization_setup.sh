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

# virtualization_setup.sh: quick setup script for a Ubuntu Server 24.04 virtual machine, using Qemu and KVM


# Helpers

text_reset="\e[0m"
text_bold="\e[97m\e[100m\e[1m" # bold white text on a gray background

announce() {
  echo -e "\n$text_reset$text_bold$*$text_reset"
}

## Detect if a program or alias exists
has() {
  [ "$(type "$1" 2> /dev/null)" ]
}

## List contents of an array (include associative arrays/dictionaries)
list() {
  array="$1"
  for i in ${array[*]}; do # what's the proper way to do this?
    echo "  $i"
  done
}


# Configs

announce "Reading configs and fetching installed packages"

declare -A dirs
dirs[virtualization]="$HOME/virt"
dirs[iso_images]="${dirs[virtualization]}/images"
dirs[disks]="${dirs[virtualization]}/disks"

## Direct links for Ubuntu can be easily gotten from https://www.releases.ubuntu.com/
declare -A iso
iso[download]=false # does NOT work! how do i do booleans in POSIX/Bash?
iso[url]="https://www.releases.ubuntu.com/noble/ubuntu-24.04-live-server-amd64.iso"
iso[file_name]="ubuntu-24.04-live-server-amd64.iso"

declare -A disk
disk[file_name]="ubuntu.qcow"
disk[size]="10G"
disk[format]="qcow2"

declare -A vm
vm[command]="qemu-system-x86_64"
vm[name]="ubuntu-vm"
vm[screen_name]="qemu-${vm[name]}"
vm[memory]="4G"
vm[aio]="io_uring" # threads, native, or io_uring
vm[serial_output]=$(tty)

declare -A packages
packages[cpu-checker]="cpu-checker"
packages[installed]=$(apt list --installed | grep --only-matching '^.*/' | sed 's/.$//')
packages[list]="qemu-kvm bridge-utils libvirt-clients libvirt-daemon screen"

if [ "$(uname -m)" = "x86_64" ]; then
  packages[qemu]="qemu-system-x86"

else
  echo "WARNING: qemu-kvm will always fail to resolve because it is a virtual package, so apt will run every time this script is run."
  echo "This script will skip qemu-kvm and check for a different package instead, but it does not resolve it automatically."
  echo "Please edit the script to specify the appropriate package for your architecture ($(uname -m)). Pull request are welcome!"

fi

# Install

## Detect if a package is installed with APT
has_package() {
  package_name="$1"
  echo "${packages[installed]}" | grep "$package_name"
}

announce "Checking for virtualization support"

[ "$(has_package "${packages[cpu-checker]}")" ] || {
  echo "${packages[cpu-checker]} not installed, installing"
  sudo apt install "${packages[cpu-checker]}"
}
kvm-ok || {
  return_val="$?"
  announce "KVM virtualization is not supported, exiting"
  exit "$return_val"
}


announce "Installing packages"

installed="false"

for package in ${packages[list]}; do
  [ "$package" = "qemu-kvm" ] && # has_package always fails on virtual packages, its necessary to check for qemu-kvm manually
    [ "$(has_package "${packages[qemu]}")" ] &&
    continue

  [ "$(has_package "$package" )" ] || {
    echo "$package not found. Installing:"
    list "${packages[list]}"

    # shellcheck disable=SC2086
    sudo apt install ${packages[list]}

    installed="true"
    break
  }
done

[ $installed = "false" ] && echo "All packges installed, skipping installation"


announce "Setting up virtualization directory"

created="false"

for dir in "${dirs[@]}"; do
  [ -d "$dir" ] || {
    mkdir -p "${dirs[virtualization]}" "${dirs[iso_images]}" "${dirs[disks]}"

    echo "Created"
    list "${dirs[*]}"

    created="true"
    break
  }
done

[ "$created" = "false" ] && echo "Add directories exist, skipping"


announce "Downloading install image"

if [ "${iso[download]}" = true ]; then
  cd "${dirs[iso_images]}" || exit

  if [ -f "${iso[file_name]}" ]; then
    curl "${iso[url]}" --output "${iso[file_name]}"

  else
    echo "ISO image already exists, skipping download"

  fi

else
  echo "Skipping download as per config"

fi


announce "Creating disk image"

cd "${dirs[disks]}" || exit

if [ -f "${disk[file_name]}" ]; then
  echo "Disk image already exists, skipping creation"

else
  qemu-img create -f "${disk[format]}" "${disk[file_name]}" "${disk[size]}"

fi


announce "Starting VM"

cd "${dirs[virtualization]}" || exit

echo "This will open in an instance of GNU Screen named ${vm[screen_name]}"
echo "Use <^a d> (ctrl+a d) to detatch (exit), and screen -r ${vm[screen_name]} to reattach"
read -rp "Hit enter to begin startup"

screen -S "${vm[screen_name]}" -- sudo "${vm[command]}" \
  -cpu host \
  -accel kvm \
  -m "${vm[memory]}" \
  -name "${vm[name]}" \
  -drive "file=${dirs[disks]}/${disk[file_name]},media=disk,aio=${vm[aio]},format=qcow2" \
  -cdrom "${dirs[iso_images]}/${iso[file_name]}" \
  -nographic \
  -display none \
  -serial "${vm[serial_output]}" \
  -runas "$(whoami)"
  # -nic -netdev
  # are -display and -nographic redundant?
