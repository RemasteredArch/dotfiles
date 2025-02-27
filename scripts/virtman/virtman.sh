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


# virtman.sh: Setup and management scripts for virtual machines using Qemu and KVM


# Functions

declare -A script
script[name]='virtman'
script[version]='v0.2'
script[authors]='RemasteredArch 2024'
script[source]="$(dirname "$(realpath "$0")")"

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

declare -A configs
configs[config_file_name]='config.toml'
configs[default_config_file_name]='default.toml'
configs[config_dir]="${XDG_CONFIG_HOME:-"$HOME/.config"}/${script[name]}"
configs[config_file]="${configs[config_dir]}/${configs[config_file_name]}"
configs[default_config_file]="${script[source]}/${configs[default_config_file_name]}"

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
  A script to manage Qemu virtual machines. Designed for use on Ubuntu 24.04.

${text[bold]}Usage:${text[reset]}
$(help_entry -h --help "Prints this help message")
$(help_entry -v --version "Prints the version of this script")
$(help_entry -i --install "Whether to load the install ISO of the virtual machine instead of booting from its disk" "" \
  "The value of virtual_machines.reinstall in the config")
$(help_entry -c --config_name "A particular config to select from the config file")
$(help_entry -f --config_file "The path to a config file" "" \
  "${configs[config_file]}" \
  "${configs[default_config_file]}")

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


# Command-line argument parsing

args=''
args=$(getopt \
    --name "${script[name]}" \
    --options 'f:,c:,i,h,v' \
    --longoptions 'config_file:,config_name:,install,help,version' \
    -- "$@") \
    || exit

eval set -- "$args"
unset args

declare -A opts
opts[config_file]="${configs[config_file]}" # Default value
opts[config_name]=''

while true; do
    case "$1" in
        -f | --config_file )
            opts[config_file]="$2"
            shift 2
            ;;
        -c | --config_name )
            opts[config_name]="$2"
            shift 2
            ;;
        -i | --install)
            opts[install]='true'
            shift
            ;;
        -h | --help )
            help
            exit 0
            ;;
        -v | -V | --version )
            version
            exit 0
            ;;
        -- )
            shift
            break
            ;;
        * )
            break
            ;;
    esac
done


# Configs

announce 'Reading configs and fetching installed packages'
if [ -f "${configs[config_file]}" ]; then
    echo -e 'Reading from user config...\n'
    config="$(cat "${configs[config_file]}")"

else
    echo -e 'Reading from default config...\n'
    config="$(cat "${configs[default_config_file]}" 2> /dev/null)"

fi

config_select() {
    echo "$config" | dasel \
        --read='toml' --write='-' \
        -- "$1"
}

readarray -t vm_configs < <(config_select '.virtual_machines.all().name')

is_valid_vm_config() {
    for name in "${vm_configs[@]}"; do
        [ "$1" = "$name" ] && return 0
    done

    return 1
}

echo 'Available configs:'
for name in "${vm_configs[@]}"; do
    echo "- $name"
done

while ! is_valid_vm_config "${opts[config_name]}"; do
    [ -n "${opts[config_name]}" ] && echo -e "Invalid config name! (${opts[config_name]})\n"

    read -rp 'Select a configuration: ' opts['config_name']

    [ -n "${opts[config_name]}" ] || {
        echo 'No config selected!'
        continue
    }
done

echo "Selected ${opts[config_name]}"

read_config() {
    local selector="$1"

    config_select ".$section.$selector"
}
expand_tilde() { # Not perfect but suitable for this use case
    echo "${1/#\~/$HOME}" # Replace leading `~` with `$HOME`
}

section='directories'
declare -A dirs
dirs[data]=$(expand_tilde "$(read_config 'data')")
dirs[config]=$(expand_tilde "$(read_config 'config')")
dirs[prefer_xdg]=$(read_config 'prefer_xdg')
dirs[isos]="${dirs[data]}/$(read_config 'isos')"
dirs[mount]="${dirs[data]}/$(read_config 'mount')"
dirs[disks]="${dirs[data]}/$(read_config 'disks')"
necessary_dirs=( # Bash does not support multi-dimensional arrays
    "${dirs[isos]}"
    "${dirs[disks]}"
    "${dirs[mount]}"
)

section="virtual_machines.all().filter(equal(name,${opts[config_name]}))"
declare -A vm
vm[name]=$(read_config 'name')
vm[reinstall]=${opts[install]:-$(read_config 'reinstall')}
vm[command]=$(read_config 'command') # replace with `kvm`?
vm[cores]=$(read_config 'cores')
vm[memory]=$(read_config 'memory')
vm[aio]=$(read_config 'aio')
vm[disk]=$(read_config 'disk')
vm[format]=$(read_config 'format')
vm[disk_path]="${dirs[disks]}/${vm[disk]}"
vm[size]=$(read_config 'size')
vm[iso]=$(read_config 'iso')

section="isos.all().filter(equal(file_name,${vm[iso]}))"
declare -A iso
iso[file_name]=$(read_config 'file_name')
iso[path]="${dirs[isos]}/${iso[file_name]}"
iso[url]=$(read_config 'url')
iso[download]=$(read_config 'download')
iso[force_redownload]=$(read_config 'force_redownload')
iso[mount_point]="${dirs[mount]}/${iso[file_name]}"

declare -A packages
packages[cpu-checker]='cpu-checker'
packages[installed]=$(apt list --installed | grep --only-matching '^.*/' | sed 's/.$//')
packages[list]='qemu-kvm bridge-utils libvirt-clients libvirt-daemon'

if [ "$(uname -m)" = 'x86_64' ]; then
    packages[qemu]='qemu-system-x86'

else
    echo 'WARNING: qemu-kvm will always fail to resolve because it is a virtual package, so apt will run every time this script is run.'
    echo 'This script will skip qemu-kvm and check for a different package instead, but it does not resolve it automatically.'
    echo "Please edit the script to specify the appropriate package for your architecture ($(uname -m)). Pull requests are welcome!"

fi


# Install

## Detect if a package is installed with APT
has_package() {
    local package_name="$1"
    echo "${packages[installed]}" | grep "$package_name"
}


announce 'Checking for virtualization support'

[ "$(has_package "${packages[cpu-checker]}")" ] || {
    echo "${packages[cpu-checker]} not installed, installing"
    sudo apt install "${packages[cpu-checker]}"
}
kvm-ok || {
    return_val="$?"
    announce 'KVM virtualization is not supported, exiting'
    exit "$return_val"
}


announce 'Installing packages'

installed='false'

for package in ${packages[list]}; do
    [ "$package" = 'qemu-kvm' ] && # has_package always fails on virtual packages, its necessary to check for qemu-kvm manually
        [ "$(has_package "${packages[qemu]}")" ] &&
        continue

    [ "$(has_package "$package")" ] || {
        echo "$package not found. Installing:"
        for i in ${packages[list]}; do
            echo "- $i"
        done

        # shellcheck disable=SC2086
        sudo apt install ${packages[list]}

        installed='true'
        break
    }
done

$installed || echo 'All packges installed, skipping installation'


announce 'Setting up necessary directories'

created='false'

for necessary_directory in "${necessary_dirs[@]}"; do
    [ -d "$necessary_directory" ] || {
        echo 'Some or all directories are missing! Will create:'

        for dirs in "${necessary_dirs[@]}"; do
            echo "- $dirs"
        done
        echo

        read -rp 'Hit enter to continue with creation'
        mkdir -p "${necessary_dirs[@]}" || exit

        created='true'
        break
    }
done

$created || echo 'All directories exist, skipping'


announce 'Downloading install image'

if ${iso[download]}; then
    cd "${dirs[isos]}" || exit

    if [ -f "${iso[file_name]}" ]; then
        echo 'ISO image already exists, skipping download'

    else
        curl "${iso[url]}" --output "${iso[file_name]}" --fail-with-body || {
            exit_code="$?"

            head -1 "${iso[file_name]}" \
                | grep --quiet --ignore-case 'html' \
                && rm "${iso[file_name]}"

            exit "$exit_code"
        }

    fi

else
    echo 'Skipping download as per config'

fi


announce 'Creating disk image'

cd "${dirs[disks]}" || exit

if [ -f "${vm[disk]}" ]; then
    echo 'Disk image already exists, skipping creation'

else
    qemu-img create -f "${vm[format]}" "${vm[disk]}" "${vm[size]}" || exit

fi


announce 'Mounting install disk and setting install-specific boot parameters'

if ${vm[reinstall]}; then
    echo -e "$(cat << EOF
If you have already installed to the virtual disk, or would otherwise like to not load the install ISO image, please edit or create a config file to set:

${text[italic]}[[virtual_machines]]
name = ${opts[config_name]}${text[reset]}
${text[bold]}reinstall = false${text[reset]}
EOF
    )"

    if [ -d "${iso[mount_point]}" ]; then
        mountpoint --quiet "${iso[mount_point]}" && sudo umount "${iso[mount_point]}" || exit

    else
        mkdir "${iso[mount_point]}" || exit

    fi

    sudo mount -r "${iso[path]}" "${iso[mount_point]}" || exit

    install_params=(
        '-cdrom' "${iso[path]}"
        '-kernel' "${iso[mount_point]}/casper/vmlinuz"
        '-initrd' "${iso[mount_point]}/casper/initrd"
        '-append' 'console=ttyS0')

else
    echo 'Skipping install steps as per config'

fi


announce 'Starting VM'

cd "${dirs[virtualization]}" || exit

echo 'This will output to stdio (directly to the terminal)'
read -rp 'Hit enter to begin startup'

sudo "${vm[command]}" \
    -cpu 'host' \
    -accel 'kvm' \
    -smp "${vm[cores]}" \
    -m "${vm[memory]}" \
    -name "${vm[name]}" \
    -drive "file=${vm[disk_path]},media=disk,aio=${vm[aio]},format=${vm[format]}" \
    -nographic \
    -runas "$(whoami)" \
    -device 'e1000,netdev=net0' \
    -netdev 'user,id=net0,hostfwd=tcp::2222-:22' \
    "${install_params[@]}"

[ -d "${iso[mount_point]}" ] && {
    mountpoint --quiet "${iso[mountpoint]}" \
        && sudo umount "${iso[mount_point]}"

    rmdir "${iso[mount_point]}"
}

exit 0
