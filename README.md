# Dotfiles

A collection of my miscellaneous scripts and configuration files. Designed for Ubuntu 24.04 [on WSL](https://apps.microsoft.com/detail/9nz3klhxdjp5).

Organized as if it will be copied directly to `$HOME`, such as with [GNU Stow](https://www.gnu.org/software/stow/). If you use an unusual `$XDG_CONFIG_HOME`, you'll have to adjust `.config/` to that directory as necessary.

## Scripts
- `scripts/dotfiles/gnome_keyring_setup.sh`
    - A simple script for setting up [GNOME Keyring](https://wiki.gnome.org/Projects/GnomeKeyring/)
- `scripts/dotfiles/install.sh`
    - A script to install and configure a fresh installation of Ubuntu 24.04 as per my preferences
    - Mostly involves installing and setting up various dev tools
    - This is COMPLETELY UNTESTED! Use at your own risk!
    - On a fresh install, run:
```bash
# Again, this is COMPLETELY UNTESTED!
temp_dir=$(mktemp --directory -t dotfiles.install.XXXXXXXX) \
  && curl "https://raw.githubusercontent.com/RemasteredArch/dotfiles/main/scripts/dotfiles/install.sh" -o "$temp_dir/install.sh" \
  && chmod u+x "$temp_dir/install.sh" \
  && "$temp_dir/install.sh"
# DO NOT RUN THIS if you are not certain that is is okay!
```
- `scripts/dotfiles/number_conversion.sh`
    - Provides a number of simple functions for binary, decimal, and hexadecimal conversions
- `scripts/virtman/virtman.sh`
    - A script for installation and management of [Qemu](https://www.qemu.org/) virtual machines

## See also

I organize some other configurations under their own repositories:
* My Neovim configuration, available at [`nvim-config`](https://github.com/RemasteredArch/nvim-config) (maps to `~/.config/nvim/`)
* My tmux configuration, available at [`tmux-config`](https://github.com/RemasteredArch/tmux-config) (maps to `~/.config/tmux/`)
* My update script, available at [`Updater`](https://github.com/RemasteredArch/Updater)

## License

Dotfiles is licensed under the GNU General Public License version 3, or (at your option) any later version. You should have received a copy of the GNU General Public License along with dotfiles, found in [`LICENSE`](./LICENSE). If not, see <[https://www.gnu.org/licenses/](https://www.gnu.org/licenses/)>.
