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

script_source_dir=$(dirname "$0")
install_script_dir="$script_source_dir"

text_reset="\e[0m"
text_bold="\e[97m\e[100m\e[1m" # bold white text on a gray background

announce() {
  echo -e "\n$text_reset$text_bold$*$text_reset"
}

# Detect if a program or alias exists
has() {
  [ "$(type "$1" 2> /dev/null)" ]
}

# Detect distro
lsb_release -i -s | grep -q Ubuntu || {
  echo "This script is designed for Ubuntu." >&2
  exit 1
}

announce "This script is COMPLETELY UNTESTED, and is only designed to be used on fresh installs of Ubuntu 24.04! Use at your own risk!"
echo "This is distributed WITHOUT ANY FORM OF WARRANTY or guarantee of functionality! Hit enter/return to continue or ^c/ctrl+c to quit."
read -r

announce "Updating"
sudo apt update && sudo apt upgrade
sudo snap refresh

announce "Installing various packages"
declare -A packages
packages[dev_tools]="openjdk-21-jdk gcc g++ clang ninja-build cmake shellcheck build-essentials gdb"
packages[utilities]="tealdeer unzip eza bat jq ripgrep fzf xeyes mesa-utils htop btop screen"
packages[theming]="gnome-themes-extra lxappearance" # TODO: make intall & update script for Catppuiccin
packages[fun]="sl neofetch"
packages[wsl]="wslu"
packages[tor]="tor tor-geoipdb torsocks"
# shellcheck disable=SC2086
sudo apt install ${packages[dev_tools]} \
  ${packages[utilities]} \
  ${packages[theming]} \
  ${packages[fun]} \
  ${packages[wsl]}
unset packages

announce "Setting up virtualization"
"$install_script_dir/virtualization_setup.sh"

announce "Installing various snaps"
sudo snap install shellcheck

announce "Installing nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash

announce "Installing node.js"
nvm install --lts

announce "Installing live-server"
npm install -g live-server

announce "Installing rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

announce "Installing rust-analyzer"
rustup component add rust-analyzer

announce "Installing starship"
curl -sS https://starship.rs/install.sh | sh

announce "Installing neovim"
sudo add-apt-repository ppa:neovim-ppa/unstable \
&& sudo apt update \
&& sudo apt install neovim
nvim --headless "+Lazy! sync" +qa

announce "Installing GitHub CLI"
sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh

announce "Updating again"
sudo apt update && sudo apt upgrade

announce "Setting up configs"
development_dir="$HOME/dev"
config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}"
user_binary_dir="$HOME/.local/bin"

mkdir "$development_dir"
cd "$development_dir" || exit 1
git clone "https://github.com/RemasteredArch/dotfiles.git"
cd "dotfiles" || exit 1
git clone "https://github.com/RemasteredArch/Updater.git"
git clone "https://github.com/RemasteredArch/nvim-config.git"
git clone "https://github.com/RemasteredArch/tmux-config.git"

announce "Setting up bash configs"
config_files=(".archrc" ".arch_aliases")
for file in "${config_files[@]}"; do
  ln -s "$file" "$HOME/$file"
done
# shellcheck disable=SC2016
echo '[ -f "$HOME/.archrc" ] && . "$HOME/.archrc"' >> "$HOME/.bashrc"

mkdir "$config_dir"
ln -s nvim-config "$config_dir/nvim"
ln -s tmux-config "$config_dir/tmux"
for file in .config/*; do
  ln -s "$file" "$config_dir/$file"
done

announce "Setting up update script"
mkdir -p "$user_binary_dir"
"$user_binary_dir/update" << EOF
#! /bin/env bash

$development_dir/dotfiles/Updater/updater.sh
EOF
chmod u+x "$user_binary_dir/updater"

announce "Setting up tmux config"
mkdir tmux-config/plugins
cd tmux-config/plugins || exit 1
git clone https://github.com/tmux-plugins/tpm
cd ../../
announce "Install tmux plugins using <^s I> (ctrl+s shift+i) while in tmux"

announce "Setting up git config"
git config --global init.defaultBranch main

read -rsp "Git username: " git_username; echo -n "$git_username"
git config --global user.name "$git_username"
unset git_username

read -rsp "Git email: " git_email; echo -n "$git_email"
git config --global user.email "$git_email"
unset git_email

announce "Authenticate Git credentials using: gh auth login"
announce "WARNING: GitHub CLI will store credentials in plain text if gnome-keyring is not set up."
echo "If gnome-keyring is not already set up, use the following script to set it up:"
echo "  $development_dir/dotfiles/scripts/dotfiles/gnome_keyring_setup.sh"
# TODO: setup gnome-keyring for git commit signing
# ~/.gnupg/gpg-agent.conf

announce "Installing pfetch"
curl https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch --output "$user_binary_dir/pfetch"
chmod u+x "$user_bin_dir/pfetch"
