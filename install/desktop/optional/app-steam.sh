#!/bin/bash

# Play games from https://store.steampowered.com/
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libgl1:i386 libdrm2:i386

cd /tmp
wget https://cdn.akamai.steamstatic.com/client/installer/steam.deb
sudo apt install -y ./steam.deb
rm steam.deb
cd -
