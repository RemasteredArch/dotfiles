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

text_reset="\e[0m"
text_bold="\e[97m\e[100m\e[1m" # bold white text on a gray background

announce() {
  echo -e "\n$text_reset$text_bold$*$text_reset"
}

announce "This script will append entries for gnome-keyring to /etc/pam.d/login and /etc/pam.d/passwd. Please read the source code of this script and confirm that no such similar passages already exist in the files."
echo "This is distributed WITHOUT ANY FORM OF WARRANTY or guarantee of functionality! Hit enter/return to continue or ^c/ctrl+c to quit."
read -r

announce "Updating"
sudo apt upgrade && sudo apt upgrade

announce "Installing gnome-keyring"
sudo apt install gnome-keyring

announce "Setting up login hook at /etc/pam.d/login"
sudo tee --append /etc/pam.d/login << EOF

# CUSTOM: initialize gnome-keyring
auth       optional   pam_gnome_keyring.so
session    optional   pam_gnome_keyring.so auto_start
EOF

announce "Setting up password change hook at /etc/pam.d/passwd"
sudo tee --append /etc/pam.d/passwd << EOF

# CUSTOM: setup gnome keyring
password        optional        pam_gnome_keyring.so
EOF

announce "Extra information"
echo "Use login(1) to unlock the default login keyring"
echo "  This can be achieved by adding the following to your startup script of choise (probably ~/.bash_aliases):"
echo "    alias relog='sudo login -p \$(whoami); exit'"
echo "Seahorse(1) (AKA Passwords and Keys) can be used to graphically view and manage keyrings and their entries"
