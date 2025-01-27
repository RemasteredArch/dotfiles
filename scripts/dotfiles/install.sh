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

{ # Stops script from being executed if it isn't fully downloaded

script_source_dir=$(dirname "$0")

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
# Ubuntu's Watchman version is severely out of date (2017).
#
# Maybe the install would be better suited to Updater pulling DPKG packages from GitHub releases?
packages[dev_tools]="openjdk-21-jdk gcc g++ clang ninja-build cmake shellcheck build-essential gdb\
    iwyu cpplint hyperfine lldb python3 python3-venv mingw-w64 watchman usbutils"
packages[utilities]="tealdeer unzip eza bat jq ripgrep fzf x11-apps mesa-utils htop btop screen dos2unix dasel bind9-dnsutils pandoc"
packages[theming]="gnome-themes-extra lxappearance" # TODO: make intall & update script for Catppuccin
packages[fun]="sl neofetch hollywood fortune-mod cowsay"
packages[wsl]="wslu" # TODO: add a check to only install on WSL
packages[tor]="tor tor-geoipdb torsocks"
packages[doc]="bash-doc"
# maybe: pre-commit

# shellcheck disable=SC2086
sudo apt install ${packages[dev_tools]} \
  ${packages[utilities]} \
  ${packages[theming]} \
  ${packages[fun]} \
  ${packages[doc]} \
  ${packages[wsl]} \
  # ${packages[tor]}
unset packages

announce "Installing various snaps"
sudo snap install shellcheck

announce "Installing nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

announce "Installing node.js"
nvm install --lts

announce "Installing live-server"
npm install -g live-server

announce "Installing Bun"
curl --fail --silent --show-error --location \
    'https://bun.sh/install' | bash

annoucnce 'Installing Deno'
curl --fail --silent --show-error --location \
    'https://deno.land/install.sh' | sh

announce "Installing rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# shellcheck disable=SC1091
. "$HOME/.cargo/env"

announce "Installing rust-analyzer"
rustup component add rust-analyzer

announce "Installing Cargo packages"
cargo install \
    'bacon' \
    'cargo-binstall' \
    'cargo-expand' \
    'cargo-license' \
    'cargo-update' \
    'fd-find' \
    'flamegraph' \
    'typst-cli'

announce "Installing starship"
curl -sS https://starship.rs/install.sh | sh

announce "Installing Neovim"
sudo add-apt-repository ppa:neovim-ppa/unstable \
&& sudo apt update \
&& sudo apt install neovim

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
cd "$development_dir" || exit
git clone "https://github.com/RemasteredArch/dotfiles.git"
cd "dotfiles" || exit
git clone "https://github.com/RemasteredArch/Updater.git"
git clone "https://github.com/RemasteredArch/nvim-config.git"
git clone "https://github.com/RemasteredArch/tmux-config.git"

announce "Setting up home directory configs"
config_files=(".archrc" ".arch_aliases" ".shellcheckrc" ".vimrc" ".lldbinit" ".mdformat")
for file in "${config_files[@]}"; do
  ln -s "$(pwd)/$file" "$HOME/$file"
done
# shellcheck disable=SC2016
echo '[ -f "$HOME/.archrc" ] && . "$HOME/.archrc"' >> "$HOME/.bashrc"

[ -d "$config_dir" ] || mkdir "$config_dir"
ln -s "$(pwd)/nvim-config" "$config_dir/nvim"
ln -s "$(pwd)/tmux-config" "$config_dir/tmux"
for file in .config/*; do
  ln -s "$file" "$config_dir/$(basename "$file")"
done

announce "Setting up update script"
mkdir -p "$user_binary_dir"
update_script="$user_binary_dir/update"
touch "$update_script"
tee "$update_script" << EOF
#! /usr/bin/env bash

# This file was generated by $development_dir/dotfiles/scripts/dotfiles/install.sh

$development_dir/dotfiles/Updater/updater.sh "\$@"
EOF
chmod u+x "$update_script"
unset update_script

announce "Setting up tmux config"
mkdir tmux-config/plugins
cd tmux-config/plugins || exit
git clone https://github.com/tmux-plugins/tpm
cd ../../
announce "Install tmux plugins using <^s I> (ctrl+s shift+i) while in tmux"

announce "Setting up git config"
git config --global init.defaultBranch main
git config --global pull.rebase false # Use merging during `git pull` conflicts

read -rp "Git username: " git_username
git config --global user.name "$git_username"

read -rp "Git email: " git_email
git config --global user.email "$git_email"
unset git_username git_email


announce "Authenticate Git credentials using: gh auth login"
announce "WARNING: GitHub CLI will store credentials in plain text if gnome-keyring is not set up."
echo "If gnome-keyring is not already set up, use the following script to set it up:"
echo "  $development_dir/dotfiles/scripts/dotfiles/gnome_keyring_setup.sh"

announce "Setting up Git commit signing"
"$development_dir/dotfiles/scripts/dotfiles/git_commit_signing_setup.sh"

announce "Installing pfetch"
curl https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch --output "$user_binary_dir/pfetch"
chmod u+x "$user_binary_dir/pfetch"

announce "Installing Docker"
sudo install --mode '0755' --directory '/etc/apt/keyrings'
sudo curl --fail --silent --show-error --location \
    'https://download.docker.com/linux/ubuntu/gpg' \
    -o '/etc/apt/keyrings/docker.asc'
sudo chmod a+r '/etc/apt/keyrings/docker.asc'
echo \
    "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee '/etc/apt/sources.list.d/docker.list' > /dev/null
sudo apt update
sudo apt install \
    'docker-ce' 'docker-ce-cli' 'containerd.io' 'docker-buildx-plugin' 'docker-compose-plugin'

announce "Installing Act"
temp_file="$(mktemp)"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    'https://raw.githubusercontent.com/nektos/act/master/install.sh' \
    -o "$temp_file"
chmod u+x "$temp_file"
"$temp_file" -b "$user_binary_dir"
rm "$temp_file"
unset temp_file


announce "Installing cloudflared"
sudo curl --fail --silent --show-error --location \
    'https://pkg.cloudflare.com/cloudflare-main.gpg' \
    -o '/etc/apt/keyrings/cloudflare-main.gpg'
sudo chmod a+r '/etc/apt/keyrings/cloudflare-main.gpg'
# I'll have to periodically check if there's a 24.04-specific repository.
# Currently, Cloudflare only has 20.04 and 22.04 PPAs.
echo \
    "deb [signed-by=/etc/apt/keyrings/cloudflare-main.gpg] \
    https://pkg.cloudflare.com/cloudflared jammy main" \
    | sudo tee '/etc/apt/sources.list.d/cloudflared.list' > /dev/null
sudo apt update
sudo apt install 'cloudflared'


announce "All done! Don't forget to:"
cat << EOF
- Enable Bash configs:
    . "$HOME/.archrc"
- Setup dependencies of the custom Neovim config
- Install tmux plugins:
    <^s I> (ctrl+s shift+i) while in tmux
- Authenticate with the GitHub CLI:
    gh auth login
EOF

exit 0

} # Stops script from being executed if it isn't fully downloaded
