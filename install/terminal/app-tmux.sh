#!/bin/bash

sudo apt install -y tmux

mkdir -p ~/.config/tmux
[ ! -f "$HOME/.config/tmux/tmux.conf" ] && cp ~/.local/share/omakub/configs/tmux.conf ~/.config/tmux/tmux.conf
cp ~/.local/share/omakub/themes/tokyo-night/tmux.conf ~/.config/tmux/theme.conf
