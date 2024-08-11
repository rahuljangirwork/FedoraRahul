#!/bin/bash


# Configure window button layout
read -r -p "Do you want to configure window button layout to ':minimize,maximize,close'? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Configuring window button layout..."
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
  echo "Window button layout configured!"
fi
