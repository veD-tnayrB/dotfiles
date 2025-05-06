#!/usr/bin/env bash

# List of packages to install
PACKAGES=(
    neovim
    dolphin
    hyprland
    waybar
    wlogout
    hyprpaper
    xclip
    gtk3
    gtk4
    hypridle
    # Add any other packages you need here
)

echo "==> Installing packages..."
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

echo "==> Symlinking config files..."

# Kitty config
ln -sf "$PWD/scripts" ~/.config/scripts

# Kitty config
ln -sf "$PWD/kitty" ~/.config/kitty

# Wallpapers config
ln -sf "$PWD/wallpapers" ~/Pictures

# Dolphin config
ln -sf "$PWD/dolphinrc" ~/.config/dolphinrc

# Hyprland configs
ln -sf "$PWD/hypr" ~/.config/hypr

# Neovim config
ln -sf "$PWD/nvim" ~/.config/nvim

# Waybar config
ln -sf "$PWD/waybar" ~/.config/waybar

# Wlogout config
ln -sf "$PWD/wlogout" ~/.config/wlogout

echo "==> Done! Your configs are installed and packages are ready."
