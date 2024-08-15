#!/bin/bash

# Exit on any error
set -e

# Install micro
# read -r -p "Do you want to install micro (text editor)? (y/n) " response
# if [[ "$response" =~ ^[yY]$ ]]; then
#   echo "Installing micro..."
#   sudo dnf install micro -y
# fi

# Edit dnf config file
read -r -p "Do you want to configure DNF? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Configuring DNF..."
  sudo bash -c 'cat >> /etc/dnf/dnf.conf <<EOF
# ADDED BY ME
defaultyes=True
max_parallel_downloads=20
fastestmirror=True
countme=False
EOF'
fi

# Update repositories and install updates
read -r -p "Do you want to update repositories and install updates? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Updating repositories and installing updates..."
  sudo dnf update --refresh -y
fi

# Install RPM Fusion Free
read -r -p "Do you want to install RPM Fusion Free? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing RPM Fusion Free..."
  sudo dnf install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
fi

# Install RPM Fusion Non-Free
read -r -p "Do you want to install RPM Fusion Non-Free? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing RPM Fusion Non-Free..."
  sudo dnf install \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
fi

# Install GUI Core Group
# read -r -p "Do you want to update core GUI group? (y/n) " response
# if [[ "$response" =~ ^[yY]$ ]]; then
#   echo "Updating core GUI group..."
#   sudo dnf group update core -y
# fi

# Install Flatpak
read -r -p "Do you want to install Flatpak? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing Flatpak..."
  sudo dnf install flatpak -y
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install codecs
read -r -p "Do you want to install multimedia codecs? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing multimedia codecs..."
  sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
  sudo dnf install lame\* --exclude=lame-devel -y
  sudo dnf group upgrade --allowerasing --with-optional Multimedia -y
fi

# Install media players
read -r -p "Do you want to install media players? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing media players..."
  sudo dnf install vlc mpv -y
fi

# Install Fish shell
# read -r -p "Do you want to install Fish shell? (y/n) " response
# if [[ "$response" =~ ^[yY]$ ]]; then
#   echo "Installing Fish shell..."
#   sudo dnf install fish -y
#   chsh -s /usr/bin/fish
# fi



# Download AppImageLauncher
read -r -p "Do you want to install AppImageLauncher? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Downloading AppImageLauncher..."
  wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
  sudo rpm -i appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
  # Clean up by removing the RPM file
  rm appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
fi

# Remove Firefox and install LibreWolf
read -r -p "Do you want to remove Firefox? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Removing Firefox..."
  sudo dnf remove firefox -y
fi

# Download the Google Chrome RPM package
read -r -p "Do you want to install Google Chrome? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Downloading Google Chrome..."
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

  # Install the downloaded package
  echo "Installing Google Chrome..."
  sudo dnf install google-chrome-stable_current_x86_64.rpm -y

  # Clean up by removing the RPM file
  rm google-chrome-stable_current_x86_64.rpm
fi




# Install gparted
read -r -p "Do you want to install gparted? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing gparted..."
  sudo dnf install gparted -y
  echo "gparted installation complete!"
fi
# Install Transmission
read -r -p "Do you want to install Transmission? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing Transmission..."
  sudo dnf install transmission-gtk -y
  echo "Transmission installation complete!"
fi


echo "All installations and configurations completed!"
