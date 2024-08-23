#!/bin/bash
termux-setup-storage
# Update and upgrade Termux packages
pkg update -y && pkg upgrade -y

# Install proot-distro to manage Linux distributions
pkg install proot-distro -y
proot-distro install ubuntu
apt install nodejs -y
proot-distro login ubuntu -- bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone1/workercreator/main/inst1.sh)"
